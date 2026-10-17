import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_strings.dart';
import '../features/profile/services/profile_service.dart';
import 'neighborhood_seeder.dart';
import 'report_common.dart' show kReportNeighborhoods, foldTr;

/// Gebze Belediyesi - Mahallemde Ekranı
/// Dosya yolu: lib/screens/neighborhood_screen.dart
///
/// Veri: Firestore `neighborhood_works` koleksiyonu
/// - Bitiş tarihi geçen çalışmalar listeden otomatik düşer.
/// - Profildeki mahalle otomatik seçili gelir; üstteki seçiciyle değiştirilebilir.

class _C {
  static const navy = Color(0xFF0A2A66);
  static const navyDeep = Color(0xFF061B45);
  static const orange = Color(0xFFFF7A00);
  static const bg = Color(0xFFF1F5FD);
  static const textDark = Color(0xFF0A1F44);
  static const textMuted = Color(0xFF5F6F8A);
  static const green = Color(0xFF2E7D32);
  static const border = Color(0xFFE4E9F2);
}

const String _kBodyFont = 'system-ui';
const List<String> _kBodyFontFallback = [
  '-apple-system',
  'Segoe UI',
  'Roboto',
  'Helvetica Neue',
  'Noto Sans',
  'Liberation Sans',
  'Arial',
  'sans-serif',
];

/// "Tüm Gebze" seçimi için işaretçi değer.
const String _kAllHoods = '__all__';

// ───────────────────────── Kategoriler ─────────────────────────

class _Cat {
  final String key;
  final IconData icon;
  final Color color;
  const _Cat(this.key, this.icon, this.color);
}

const _cats = <_Cat>[
  _Cat('kazi', Icons.construction_rounded, Color(0xFFF57C00)),
  _Cat('altyapi', Icons.plumbing_rounded, Color(0xFF0288D1)),
  _Cat('cevre', Icons.park_rounded, Color(0xFF2E7D32)),
  _Cat('yol_bakim', Icons.edit_road_rounded, Color(0xFF6A1B9A)),
];

_Cat _catOf(String key) =>
    _cats.firstWhere((c) => c.key == key, orElse: () => _cats.first);

// ───────────────────────── Metinler (tr / en / ar) ─────────────────────────

String _t(String lang, String key) =>
    _strings[lang]?[key] ?? _strings['tr']![key] ?? key;

const Map<String, Map<String, String>> _strings = {
  'tr': {
    'sub': 'Mahallendeki kazı, altyapı, çevre ve yol çalışmaları',
    'all': 'Tümü',
    'kazi': 'Kazı',
    'altyapi': 'Altyapı',
    'cevre': 'Çevre',
    'yol_bakim': 'Yol Bakım',
    'all_gebze': 'Tüm Gebze',
    'pick_title': 'Mahalle Seç',
    'pick_sub': 'Sadece seçtiğin mahallenin çalışmaları listelenir.',
    'my_hood': 'Mahallem',
    'ongoing': 'Devam Ediyor',
    'planned': 'Planlandı',
    'ends_today': 'Bugün bitiyor',
    'days_left': 'gün kaldı',
    'starts_in': 'gün sonra başlıyor',
    'empty': 'Bu mahallede aktif veya planlı çalışma yok.',
    'empty_sub': 'Tüm Gebze\'yi seçerek diğer mahalleleri görebilirsin.',
    'error': 'Bir hata oluştu',
    'unit': 'Birim',
  },
  'en': {
    'sub': 'Excavation, infrastructure, environment and road works nearby',
    'all': 'All',
    'kazi': 'Excavation',
    'altyapi': 'Infrastructure',
    'cevre': 'Environment',
    'yol_bakim': 'Road Works',
    'all_gebze': 'All Gebze',
    'pick_title': 'Pick Neighborhood',
    'pick_sub': 'Only works in the selected neighborhood are listed.',
    'my_hood': 'My neighborhood',
    'ongoing': 'In progress',
    'planned': 'Planned',
    'ends_today': 'Ends today',
    'days_left': 'days left',
    'starts_in': 'days until start',
    'empty': 'No active or planned works in this neighborhood.',
    'empty_sub': 'Choose All Gebze to see other neighborhoods.',
    'error': 'An error occurred',
    'unit': 'Unit',
  },
  'ar': {
    'sub': 'أعمال الحفر والبنية التحتية والبيئة والطرق في حيّك',
    'all': 'الكل',
    'kazi': 'حفريات',
    'altyapi': 'بنية تحتية',
    'cevre': 'بيئة',
    'yol_bakim': 'صيانة الطرق',
    'all_gebze': 'كل غيبزه',
    'pick_title': 'اختر الحي',
    'pick_sub': 'تُعرض فقط أعمال الحي المحدد.',
    'my_hood': 'حيّي',
    'ongoing': 'جارٍ',
    'planned': 'مخطط',
    'ends_today': 'ينتهي اليوم',
    'days_left': 'يوم متبقٍ',
    'starts_in': 'يوم حتى البدء',
    'empty': 'لا توجد أعمال جارية أو مخططة في هذا الحي.',
    'empty_sub': 'اختر كل غيبزه لرؤية الأحياء الأخرى.',
    'error': 'حدث خطأ',
    'unit': 'الجهة',
  },
};

// ───────────────────────── Model ─────────────────────────

class _Work {
  final String id;
  final String title;
  final String description;
  final String category;
  final String neighborhood;
  final String address;
  final String unit;
  final DateTime start;
  final DateTime end;

  const _Work({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.neighborhood,
    required this.address,
    required this.unit,
    required this.start,
    required this.end,
  });

  static DateTime? _dt(dynamic v) => v is Timestamp ? v.toDate() : null;

  /// Tarihi okunamayan kayıt null döner (listede gösterilmez).
  static _Work? fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final s = _dt(m['startDate']);
    final e = _dt(m['endDate']);
    if (s == null || e == null) return null;
    return _Work(
      id: d.id,
      title: (m['title'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
      category: (m['category'] ?? 'kazi').toString(),
      neighborhood: (m['neighborhood'] ?? '').toString(),
      address: (m['address'] ?? '').toString(),
      unit: (m['unit'] ?? '').toString(),
      start: s,
      end: e,
    );
  }

  bool isExpired(DateTime now) => end.isBefore(now);
  bool isOngoing(DateTime now) => !start.isAfter(now) && !end.isBefore(now);
}

// ───────────────────────── Ekran ─────────────────────────

class NeighborhoodScreen extends ConsumerStatefulWidget {
  const NeighborhoodScreen({super.key});

  @override
  ConsumerState<NeighborhoodScreen> createState() => _NeighborhoodScreenState();
}

class _NeighborhoodScreenState extends ConsumerState<NeighborhoodScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  Timer? _ticker;
  DateTime _now = DateTime.now();

  /// null  -> kullanıcı elle seçmedi, profil mahallesi kullanılır
  /// _kAllHoods -> "Tüm Gebze"
  /// diğer -> elle seçilen mahalle
  String? _manualHood;

  /// 0 = Tümü, 1.. = _cats[i-1]
  int _catFilter = 0;

  @override
  void initState() {
    super.initState();
    // Sunucu tarafı filtre: bitiş tarihi geçmiş kayıtlar hiç gelmez.
    // Tek alan üzerinde olduğu için ek index gerekmez.
    _stream = FirebaseFirestore.instance
        .collection('neighborhood_works')
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('endDate')
        .snapshots();

    // Ekran açıkken süresi dolanlar da düşsün diye her dakika yeniden süz.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Profildeki mahalle adını listedeki yazımla eşleştirir.
  String? _profileHood() {
    final raw = ref.watch(profileProvider).value?.neighborhood;
    if (raw == null || raw.trim().isEmpty) return null;
    final f = foldTr(raw);
    for (final n in kReportNeighborhoods) {
      final fn = foldTr(n);
      if (f == fn || f.contains(fn)) return n;
    }
    return null;
  }

  /// Aktif mahalle: elle seçim varsa o, yoksa profil, yoksa tümü.
  String get _activeHood {
    if (_manualHood != null) return _manualHood!;
    return _profileHood() ?? _kAllHoods;
  }

  void _openPicker(String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _activeHood;
    final suffix = AppStrings.get('mahalle_suffix', lang);
    final mine = _profileHood();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final options = <String>[_kAllHoods, ...kReportNeighborhoods];
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _t(lang, 'pick_title'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : _C.textDark,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              Text(
                _t(lang, 'pick_sub'),
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5FD),
                  ),
                  itemBuilder: (context, i) {
                    final n = options[i];
                    final isAll = n == _kAllHoods;
                    final selected = n == active;
                    final label = isAll ? _t(lang, 'all_gebze') : '$n $suffix';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      leading: Icon(
                        isAll
                            ? Icons.public_rounded
                            : Icons.location_city_rounded,
                        color: selected
                            ? (isDark ? const Color(0xFF60A5FA) : _C.navy)
                            : (isDark ? const Color(0xFF94A3B8) : _C.textMuted),
                        size: 22,
                      ),
                      title: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: selected
                              ? (isDark ? const Color(0xFF60A5FA) : _C.navy)
                              : (isDark ? Colors.white : _C.textDark),
                        ),
                      ),
                      subtitle: (!isAll && n == mine)
                          ? Text(
                              _t(lang, 'my_hood'),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: _C.orange,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                      trailing: selected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: isDark ? const Color(0xFF60A5FA) : _C.navy,
                            )
                          : null,
                      onTap: () {
                        setState(() => _manualHood = n);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _seed() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count = await NeighborhoodSeeder.seed();
      messenger.showSnackBar(
        SnackBar(content: Text('$count demo kayıt Firebase\'e yüklendi.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Yükleme hatası: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final base = Theme.of(context);
    final isDark = base.brightness == Brightness.dark;
    final active = _activeHood;

    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(
          fontFamily: _kBodyFont,
          fontFamilyFallback: _kBodyFontFallback,
          bodyColor: isDark ? Colors.white : const Color(0xFF0A1F44),
          displayColor: isDark ? Colors.white : const Color(0xFF0A1F44),
        ),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : _C.bg,
          body: Column(
            children: [
              _Header(lang: lang, onSeed: kDebugMode ? _seed : null),
              _HoodSelector(
                lang: lang,
                label: active == _kAllHoods
                    ? _t(lang, 'all_gebze')
                    : '$active ${AppStrings.get('mahalle_suffix', lang)}',
                isMine: _manualHood == null && _profileHood() != null,
                onTap: () => _openPicker(lang),
              ),
              _buildCategoryChips(lang),
              Expanded(child: _buildList(lang, active)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labels = [_t(lang, 'all'), for (final c in _cats) _t(lang, c.key)];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final sel = _catFilter == i;
          return ChoiceChip(
            label: Text(
              labels[i],
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                color: sel
                    ? Colors.white
                    : (isDark ? Colors.white70 : _C.textDark),
              ),
            ),
            selected: sel,
            selectedColor: isDark ? const Color(0xFF2563EB) : _C.navy,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            side: BorderSide(
              color: sel
                  ? (isDark ? const Color(0xFF2563EB) : _C.navy)
                  : (isDark ? const Color(0xFF334155) : _C.border),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            showCheckmark: false,
            onSelected: (_) => setState(() => _catFilter = i),
          );
        },
      ),
    );
  }

  Widget _buildList(String lang, String activeHood) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '${_t(lang, 'error')}: ${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _C.textMuted),
              ),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = (snap.data?.docs ?? [])
            .map(_Work.fromDoc)
            .whereType<_Work>()
            // İstemci tarafı: süresi dolanları anında düşür.
            .where((w) => !w.isExpired(_now))
            .where(
              (w) =>
                  activeHood == _kAllHoods ||
                  foldTr(w.neighborhood) == foldTr(activeHood),
            )
            .where(
              (w) => _catFilter == 0 || w.category == _cats[_catFilter - 1].key,
            )
            .toList();

        // Devam edenler önce, sonra başlangıç tarihine göre.
        all.sort((a, b) {
          final ao = a.isOngoing(_now) ? 0 : 1;
          final bo = b.isOngoing(_now) ? 0 : 1;
          if (ao != bo) return ao.compareTo(bo);
          return a.start.compareTo(b.start);
        });

        if (all.isEmpty) return _EmptyState(lang: lang);

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: all.length,
          itemBuilder: (_, i) => _WorkCard(work: all[i], lang: lang, now: _now),
        );
      },
    );
  }
}

// ───────────────────────── Üst Başlık ─────────────────────────

class _Header extends StatelessWidget {
  final String lang;
  final VoidCallback? onSeed;
  const _Header({required this.lang, this.onSeed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.navy, _C.navyDeep],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      AppStrings.get('service_neighborhood', lang),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Sadece debug modda görünür: demo verileri Firebase'e yükler.
                  if (onSeed != null)
                    IconButton(
                      tooltip: 'Demo verileri yükle',
                      onPressed: onSeed,
                      icon: const Icon(
                        Icons.cloud_upload_rounded,
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_city_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48, top: 4),
                child: Text(
                  _t(lang, 'sub'),
                  style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Mahalle Seçici ─────────────────────────

class _HoodSelector extends StatelessWidget {
  final String lang;
  final String label;
  final bool isMine;
  final VoidCallback onTap;
  const _HoodSelector({
    required this.lang,
    required this.label,
    required this.isMine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : _C.border,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: _C.orange,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : _C.textDark,
                    ),
                  ),
                ),
                if (isMine)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF451A03)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _t(lang, 'my_hood'),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: _C.orange,
                      ),
                    ),
                  ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Çalışma Kartı ─────────────────────────

class _WorkCard extends StatelessWidget {
  final _Work work;
  final String lang;
  final DateTime now;
  const _WorkCard({required this.work, required this.lang, required this.now});

  String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    // Cihaz saat diliminden bağımsız olarak Türkiye saati (UTC+3) göster.
    final t = d.toUtc().add(const Duration(hours: 3));
    return '${two(t.day)}.${two(t.month)}.${t.year} ${two(t.hour)}:${two(t.minute)}';
  }

  String _remaining() {
    if (work.isOngoing(now)) {
      final days = work.end.difference(now).inDays;
      return days <= 0
          ? _t(lang, 'ends_today')
          : '$days ${_t(lang, 'days_left')}';
    }
    final days = work.start.difference(now).inDays + 1;
    return '$days ${_t(lang, 'starts_in')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cat = _catOf(work.category);
    final ongoing = work.isOngoing(now);
    final statusColor = ongoing
        ? _C.orange
        : (isDark ? const Color(0xFF93C5FD) : _C.navy);
    final statusBg = ongoing
        ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFFF3E0))
        : (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFE8EEFA));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cat.color.withAlpha(isDark ? 50 : 30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cat.icon, color: cat.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      work.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : _C.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _t(lang, work.category),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: cat.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ongoing ? _t(lang, 'ongoing') : _t(lang, 'planned'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (work.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              work.description,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: isDark ? const Color(0xFFCBD5E1) : _C.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.withAlpha(35)),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.location_on_rounded,
            text: work.address.isNotEmpty
                ? '${work.neighborhood} – ${work.address}'
                : work.neighborhood,
            bold: true,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.schedule_rounded,
            text: '${_fmt(work.start)}  ➔  ${_fmt(work.end)}',
          ),
          if (work.unit.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.business_rounded,
              text: '${_t(lang, 'unit')}: ${work.unit}',
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _remaining(),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: ongoing ? _C.orange : _C.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool bold;
  const _InfoRow({required this.icon, required this.text, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: bold ? 12.5 : 11.5,
              color: bold
                  ? (isDark ? Colors.white : _C.textDark)
                  : (isDark ? const Color(0xFF94A3B8) : _C.textMuted),
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Boş Durum ─────────────────────────

class _EmptyState extends StatelessWidget {
  final String lang;
  const _EmptyState({required this.lang});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: _C.green,
            ),
            const SizedBox(height: 12),
            Text(
              _t(lang, 'empty'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : _C.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _t(lang, 'empty_sub'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

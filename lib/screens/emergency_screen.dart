import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/localization/app_strings.dart';
import 'assembly_service.dart';

class _C {
  static const navy = Color(0xFF0A2A66);
  static const navyDeep = Color(0xFF061B45);
  static const orange = Color(0xFFFF7A00);
  static const bg = Color(0xFFF6F8FC);
  static const line = Color(0xFFE4E9F2);
  static const textDark = Color(0xFF0A1F44);
  static const textMuted = Color(0xFF5F6F8A);
  static const danger = Color(0xFFE5231B);
  static const green = Color(0xFF2E7D32);
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

BoxDecoration _cardDeco([double r = 18, bool isDark = false]) => BoxDecoration(
  color: isDark ? const Color(0xFF1E293B) : Colors.white,
  borderRadius: BorderRadius.circular(r),
  border: Border.all(color: isDark ? const Color(0xFF334155) : _C.line),
);

String _l3(String lang, String tr, String en, String ar) =>
    lang == 'en' ? en : (lang == 'ar' ? ar : tr);

String _kindLabel(AreaKind k, String lang) {
  switch (k) {
    case AreaKind.park:
      return _l3(lang, 'Park', 'Park', 'حديقة');
    case AreaKind.market:
      return _l3(lang, 'Pazar Alanı', 'Market Area', 'منطقة السوق');
    case AreaKind.picnic:
      return _l3(lang, 'Mesire Alanı', 'Recreation Area', 'منطقة ترفيهية');
    case AreaKind.school:
      return _l3(lang, 'Okul / Eğitim Tesisi', 'School / Education', 'مدرسة / منشأة تعليمية');
    case AreaKind.hospital:
      return _l3(lang, 'Sağlık Tesisi', 'Health Facility', 'منشأة صحية');
    case AreaKind.forest:
      return _l3(lang, 'Orman / Doğa Alanı', 'Forest / Nature Area', 'غابة / منطقة طبيعية');
    case AreaKind.municipal:
      return _l3(lang, 'Belediye Alanı', 'Municipal Area', 'منطقة بلدية');
    case AreaKind.sport:
      return _l3(lang, 'Spor Tesisi', 'Sports Facility', 'منشأة رياضية');
    case AreaKind.other:
      return _l3(lang, 'Toplanma Alanı', 'Assembly Area', 'منطقة تجمع');
  }
}

List<String> _facilityLabels(AssemblyArea a, String lang) => [
  if (a.hasElectricity) _l3(lang, 'Elektrik', 'Electricity', 'كهرباء'),
  if (a.hasWater) _l3(lang, 'Su', 'Water', 'ماء'),
  if (a.hasWc) _l3(lang, 'WC', 'Toilet', 'دورة مياه'),
];

String _subtitleOf(AssemblyArea a, String lang) {
  final hood = '${a.neighborhood} ${AppStrings.get('mahalle_suffix', lang)}';
  return a.street.isEmpty ? hood : '$hood • ${a.street}';
}

String _featuresOf(AssemblyArea a, String lang) => [
  if (a.areaText.isNotEmpty) a.areaText,
  ..._facilityLabels(a, lang),
].join(' • ');

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  String _searchAreaQuery = '';
  Position? _pos;

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) setState(() => _pos = p);
    } catch (_) {}
  }

  /// Konum varsa kullanıcıya, yoksa Gebze merkezine olan mesafe (km).
  double _distanceOf(AssemblyArea a) =>
      Geolocator.distanceBetween(
        _pos?.latitude ?? kGebzeCenterLat,
        _pos?.longitude ?? kGebzeCenterLng,
        a.latitude,
        a.longitude,
      ) /
      1000;

  String _l(String lang, String tr, String en, String ar) =>
      lang == 'en' ? en : (lang == 'ar' ? ar : tr);

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _C.navyDeep,
        ),
      );
  }

  /// Harita uygulamasında yol tarifi açar.
  /// Sırayla: platforma özel yerel uygulama → Google Maps web/uygulama → geo:
  Future<void> _openInMap(AssemblyArea area, String lang) async {
    final lat = area.latitude.toStringAsFixed(6);
    final lng = area.longitude.toStringAsFixed(6);
    final dest = '$lat,$lng';
    final label = Uri.encodeComponent(area.name);

    final candidates = <Uri>[
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        Uri.parse('google.navigation:q=$dest&mode=d'),
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS))
        Uri.parse('https://maps.apple.com/?daddr=$dest&q=$label&dirflg=d'),
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$dest&travelmode=driving',
      ),
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        Uri.parse('geo:$dest?q=$dest($label)'),
    ];

    for (final uri in candidates) {
      try {
        // canLaunchUrl Android 11+ <queries> olmadan yanlış false döner;
        // bu yüzden doğrudan launchUrl deniyoruz.
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {}
    }
    _toast(
      _l(
        lang,
        'Harita uygulaması açılamadı.',
        'Could not open the maps app.',
        'تعذر فتح تطبيق الخرائط.',
      ),
    );
  }

  Future<void> _callNumber(String title, String number, String lang) async {
    try {
      if (await launchUrl(Uri(scheme: 'tel', path: number))) return;
    } catch (_) {}
    _toast(AppStrings.get('call_failed_toast', lang).replaceAll('{0}', number));
  }

  void _showAreaDetail(AssemblyArea a, String lang, bool isDark) {
    final dist = _distanceOf(a);
    final facilities = _facilityLabels(a, lang);
    final cap = a.estimatedCapacity;
    final muted = isDark ? const Color(0xFF94A3B8) : _C.textMuted;
    final text = isDark ? Colors.white : _C.textDark;

    Widget row(IconData i, String t) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(i, size: 18, color: _C.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t,
              style: TextStyle(fontSize: 13, height: 1.35, color: text),
            ),
          ),
        ],
      ),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  a.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${a.neighborhood} ${AppStrings.get('mahalle_suffix', lang)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 12),
                row(
                  Icons.location_on_rounded,
                  a.street.isEmpty ? a.neighborhood : a.street,
                ),
                row(
                  Icons.near_me_rounded,
                  '${dist.toStringAsFixed(1)} km ${_pos == null ? _l(lang, '(Gebze merkezine)', '(from Gebze center)', '(من مركز جبزه)') : ''}',
                ),
                row(Icons.category_rounded, _kindLabel(a.kind, lang)),
                if (a.areaText.isNotEmpty)
                  row(
                    Icons.square_foot_rounded,
                    '${_l(lang, 'Alan', 'Area', 'المساحة')}: ${a.areaText}',
                  ),
                if (cap != null)
                  row(
                    Icons.groups_rounded,
                    '${_l(lang, 'Tahmini kapasite', 'Estimated capacity', 'السعة التقديرية')}: ~$cap ${_l(lang, 'kişi', 'people', 'شخص')}',
                  ),
                if (facilities.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final f in facilities)
                        Chip(
                          avatar: const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: _C.green,
                          ),
                          label: Text(
                            f,
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
                row(
                  Icons.my_location_rounded,
                  '${a.latitude.toStringAsFixed(5)}, ${a.longitude.toStringAsFixed(5)}',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _openInMap(a, lang),
                        icon: const Icon(Icons.directions_rounded, size: 18),
                        label: Text(AppStrings.get('btn_directions', lang)),
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF2563EB)
                              : _C.navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text:
                                '${a.name}, ${_subtitleOf(a, lang)}\n${a.latitude}, ${a.longitude}',
                          ),
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        _toast(
                          _l(
                            lang,
                            'Adres kopyalandı.',
                            'Address copied.',
                            'تم نسخ العنوان.',
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(_l(lang, 'Kopyala', 'Copy', 'نسخ')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<AssemblyArea> _filterAreas(List<AssemblyArea> areas, String lang) {
    final q = _searchAreaQuery.trim().toLowerCase();
    final list = q.isEmpty
        ? [...areas]
        : areas
              .where(
                (a) =>
                    a.name.toLowerCase().contains(q) ||
                    a.neighborhood.toLowerCase().contains(q) ||
                    a.street.toLowerCase().contains(q) ||
                    _kindLabel(a.kind, lang).toLowerCase().contains(q),
              )
              .toList();
    list.sort((a, b) => _distanceOf(a).compareTo(_distanceOf(b)));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final base = Theme.of(context);
    final isDark = base.brightness == Brightness.dark;
    final async = ref.watch(assemblyAreasProvider);
    final result = async.value;
    final areas = _filterAreas(result?.areas ?? const [], lang);

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
              _Header(lang: lang),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    // 112 Butonu
                    _MainCallCard(
                      title: AppStrings.get('call_center_112_title', lang),
                      subtitle: AppStrings.get('call_center_112_sub', lang),
                      phone: '112',
                      isDark: isDark,
                      onTap: () => _callNumber(
                        AppStrings.get('call_center_112_title', lang),
                        '112',
                        lang,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Hızlı Yardım Numaraları
                    _SectionLabel(
                      AppStrings.get('quick_call_label', lang),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickCallBox(
                            title: AppStrings.get('gebze_bld_label', lang),
                            subtitle: AppStrings.get('white_desk_sub', lang),
                            number: '444 1 890',
                            icon: Icons.account_balance_rounded,
                            color: isDark ? const Color(0xFF60A5FA) : _C.navy,
                            isDark: isDark,
                            onTap: () => _callNumber(
                              AppStrings.get('gebze_bld_label', lang),
                              '4441890',
                              lang,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickCallBox(
                            title: AppStrings.get('afad_label', lang),
                            subtitle: AppStrings.get('afad_sub', lang),
                            number: '122',
                            icon: Icons.shield_rounded,
                            color: _C.orange,
                            isDark: isDark,
                            onTap: () => _callNumber(
                              AppStrings.get('afad_label', lang),
                              '122',
                              lang,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // Toplanma Alanları Başlığı ve Sayaç
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionLabel(
                          AppStrings.get('assembly_areas_label', lang),
                          isDark: isDark,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : _C.navy.withAlpha(16),
                            borderRadius: BorderRadius.circular(20),
                            border: isDark
                                ? Border.all(color: const Color(0xFF334155))
                                : null,
                          ),
                          child: Text(
                            AppStrings.get(
                              'areas_count_badge',
                              lang,
                            ).replaceAll('{0}', areas.length.toString()),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? const Color(0xFF60A5FA) : _C.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Mahalle / Alan Arama Input'u
                    Container(
                      height: 46,
                      decoration: _cardDeco(14, isDark),
                      child: TextField(
                        onChanged: (val) =>
                            setState(() => _searchAreaQuery = val),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : _C.textDark,
                        ),
                        decoration: InputDecoration(
                          filled: false,
                          fillColor: Colors.transparent,
                          hintText: AppStrings.get('search_assembly_hint', lang),
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : _C.textMuted,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : _C.textMuted,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (result?.fromCache == true)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 14,
                              color: _C.orange,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _l(
                                  lang,
                                  'Çevrimdışı: son kaydedilen liste gösteriliyor.',
                                  'Offline: showing the last saved list.',
                                  'غير متصل: عرض آخر قائمة محفوظة.',
                                ),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : _C.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Toplanma Alanı Kartları
                    if (async.isLoading && result == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (async.hasError && result == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Text(
                              _l(
                                lang,
                                'Toplanma alanları yüklenemedi. İnternet bağlantınızı kontrol edin.',
                                'Could not load assembly areas. Check your connection.',
                                'تعذر تحميل مناطق التجمع. تحقق من الاتصال.',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : _C.textMuted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  ref.invalidate(assemblyAreasProvider),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(_l(lang, 'Tekrar dene', 'Retry', 'إعادة المحاولة')),
                            ),
                          ],
                        ),
                      )
                    else if (areas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            AppStrings.get('no_assembly_found', lang),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : _C.textMuted,
                            ),
                          ),
                        ),
                      )
                    else
                      for (final area in areas) ...[
                        _AssemblyAreaCard(
                          area: area,
                          isNearest: _pos != null &&
                              _searchAreaQuery.trim().isEmpty &&
                              identical(area, areas.first),
                          nearestLabel: _l(lang, 'En yakın', 'Nearest', 'الأقرب'),
                          subtitle: _subtitleOf(area, lang),
                          features: _featuresOf(area, lang),
                          distanceKm: _distanceOf(area),
                          directionsLabel: AppStrings.get('btn_directions', lang),
                          isDark: isDark,
                          onNavigate: () => _openInMap(area, lang),
                          onTap: () => _showAreaDetail(area, lang, isDark),
                        ),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, {this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: _C.orange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : _C.navy,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Üst Başlık ─────────────────────────

class _Header extends StatelessWidget {
  final String lang;
  const _Header({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE5231B), Color(0xFFB71C1C)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33E5231B),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(36),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('emergency_screen_title', lang),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.get('emergency_screen_sub', lang),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: _C.danger,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── 112 Çağrı Kartı ─────────────────────────

class _MainCallCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String phone;
  final bool isDark;
  final VoidCallback onTap;

  const _MainCallCard({
    required this.title,
    required this.subtitle,
    required this.phone,
    this.isDark = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.danger, width: 1.6),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _C.danger.withAlpha(isDark ? 40 : 24),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_in_talk_rounded,
                  color: _C.danger,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : _C.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFCBD5E1) : _C.textMuted,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: _C.danger,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  phone,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Hızlı Arama Butonları ─────────────────────────

class _QuickCallBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final String number;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickCallBox({
    required this.title,
    required this.subtitle,
    required this.number,
    required this.icon,
    required this.color,
    this.isDark = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(18, isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(isDark ? 45 : 26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 21),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _C.green.withAlpha(isDark ? 45 : 24),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_rounded,
                      color: _C.green,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : _C.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFFCBD5E1) : _C.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                number,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Toplanma Alanı Kartı ─────────────────────────

class _AssemblyAreaCard extends StatelessWidget {
  final AssemblyArea area;
  final bool isNearest;
  final String nearestLabel;
  final String subtitle;
  final String features;
  final double distanceKm;
  final String directionsLabel;
  final bool isDark;
  final VoidCallback onNavigate;
  final VoidCallback onTap;

  const _AssemblyAreaCard({
    required this.area,
    this.isNearest = false,
    this.nearestLabel = '',
    required this.subtitle,
    required this.features,
    required this.distanceKm,
    required this.directionsLabel,
    this.isDark = false,
    required this.onNavigate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: isNearest
            ? _cardDeco(18, isDark).copyWith(
                border: Border.all(color: _C.orange, width: 1.8),
              )
            : _cardDeco(18, isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNearest) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.near_me_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      nearestLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _C.green.withAlpha(isDark ? 45 : 24),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: _C.green,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        area.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : _C.textDark,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : _C.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E3A8A)
                        : _C.navy.withAlpha(16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.near_me_rounded,
                        size: 12,
                        color: isDark ? const Color(0xFF93C5FD) : _C.navy,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${distanceKm.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFF93C5FD) : _C.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: _C.orange,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          features,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : _C.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.directions_rounded, size: 15),
                  label: Text(directionsLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF2563EB)
                        : _C.navy.withAlpha(16),
                    foregroundColor: isDark ? Colors.white : _C.navy,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_strings.dart';

class _C {
  static const navy = Color(0xFF0A2A66);
  static const navyDeep = Color(0xFF061B45);
  static const orange = Color(0xFFFF7A00);
  static const bg = Color(0xFFF1F5FD);
  static const textDark = Color(0xFF0A1F44);
  static const textMuted = Color(0xFF5F6F8A);

  static const water = Color(0xFF0288D1);
  static const electric = Color(0xFFF57C00);
  static const gas = Color(0xFFE53935);
}

DateTime? _parseOutageDate(dynamic v, {bool endOfDay = false}) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is! String) return null;
  final s = v.trim();
  final m = RegExp(
    r'^(\d{1,2})[./](\d{1,2})[./](\d{4})(?:\s+(\d{1,2}):(\d{2}))?$',
  ).firstMatch(s);
  if (m != null) {
    final hasTime = m.group(4) != null;
    return DateTime(
      int.parse(m.group(3)!),
      int.parse(m.group(2)!),
      int.parse(m.group(1)!),
      hasTime ? int.parse(m.group(4)!) : (endOfDay ? 23 : 0),
      hasTime ? int.parse(m.group(5)!) : (endOfDay ? 59 : 0),
    );
  }
  return DateTime.tryParse(s);
}

String _fmtOutageDate(DateTime d) {
  String p(int n) => n.toString().padLeft(2, '0');
  return '${p(d.day)}.${p(d.month)}.${d.year} ${p(d.hour)}:${p(d.minute)}';
}

const String _kBodyFont = 'Poppins';
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

class OutagesScreen extends ConsumerStatefulWidget {
  const OutagesScreen({super.key});

  @override
  ConsumerState<OutagesScreen> createState() => _OutagesScreenState();
}

class _OutagesScreenState extends ConsumerState<OutagesScreen> {
  int _selectedFilter = 0;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _outagesStream =
      FirebaseFirestore.instance.collection('outages').limit(50).snapshots();

  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFallbackOutages(String lang) {
    final mahalleSuffix = AppStrings.get('mahalle_suffix', lang);
    final n = DateTime.now();
    DateTime at(int dayOffset, int hour) =>
        DateTime(n.year, n.month, n.day + dayOffset, hour);
    return [
      {
        'type': 'su',
        'title': lang == 'en'
            ? 'Main Transmission Line Maintenance'
            : lang == 'ar'
            ? 'صيانة خط النقل الرئيسي'
            : 'Ana İsale Hattı Bakım Çalışması',
        'neighborhood': 'Osman Yılmaz & Köşklü Çeşme $mahalleSuffix',
        'startDate': n.subtract(const Duration(hours: 2)),
        'endDate': n.add(const Duration(hours: 4)),
        'provider': 'İSU',
      },
      {
        'type': 'elektrik',
        'title': lang == 'en'
            ? 'Transformer Renewal & Grid Improvement'
            : lang == 'ar'
            ? 'تجديد المحولات وتحسين الشبكة'
            : 'Trafo Yenileme ve Şebeke İyileştirme',
        'neighborhood': 'Arapçeşme $mahalleSuffix',
        'startDate': at(1, 9),
        'endDate': at(1, 14),
        'provider': 'SEDAŞ',
      },
      {
        'type': 'gaz',
        'title': lang == 'en'
            ? 'Infrastructure Connection & Valve Replacement'
            : lang == 'ar'
            ? 'ربط البنية التحتية واستبدال الصمامات'
            : 'Altyapı Bağlantı ve Vana Değişimi',
        'neighborhood': 'Mustafapaşa $mahalleSuffix 712. Sokak',
        'startDate': at(2, 13),
        'endDate': at(2, 17),
        'provider': 'PALGAZ',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final base = Theme.of(context);
    final isDark = base.brightness == Brightness.dark;
    final fallbackOutages = _getFallbackOutages(lang);

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
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0F172A)
              : _C.bg,
          body: Column(
            children: [
              _Header(lang: lang),
              _buildFilterChips(lang),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _outagesStream,
                  builder: (context, snapshot) {
                    List<Map<String, dynamic>> items = [];

                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      items = snapshot.data!.docs.map((d) => d.data()).toList();
                    } else {
                      items = fallbackOutages;
                    }

                    final now = _now;
                    final processed = <Map<String, dynamic>>[];
                    for (final raw in items) {
                      final start = _parseOutageDate(raw['startDate']);
                      final end = _parseOutageDate(
                        raw['endDate'],
                        endOfDay: true,
                      );
                      if (end != null && end.isBefore(now)) continue;

                      var status = (raw['status'] ?? '').toString();
                      final low = status.toLowerCase();
                      if (low.contains('tamam') || low.contains('complete')) {
                        continue;
                      }
                      if (start != null) {
                        status = start.isAfter(now) ? 'planlı' : 'devam';
                      }

                      processed.add({
                        ...raw,
                        'status': status,
                        'startDate': start != null
                            ? _fmtOutageDate(start)
                            : raw['startDate'],
                        'endDate': end != null
                            ? _fmtOutageDate(end)
                            : raw['endDate'],
                        '_sort': start ?? end ?? DateTime(2100),
                      });
                    }
                    processed.sort(
                      (a, b) => (a['_sort'] as DateTime).compareTo(
                        b['_sort'] as DateTime,
                      ),
                    );

                    final filtered = processed.where((item) {
                      final type = (item['type'] ?? '')
                          .toString()
                          .toLowerCase();
                      if (_selectedFilter == 1) {
                        return type == 'su';
                      }
                      if (_selectedFilter == 2) {
                        return type == 'elektrik';
                      }
                      if (_selectedFilter == 3) {
                        return type == 'gaz' || type == 'dogalgaz';
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 48,
                                color: Color(0xFF2E7D32),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                AppStrings.get('no_outages_found', lang),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _C.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _OutageCard(data: filtered[index], lang: lang);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(String lang) {
    final filters = [
      AppStrings.get('filter_all', lang),
      AppStrings.get('filter_water', lang),
      AppStrings.get('filter_electric', lang),
      AppStrings.get('filter_gas', lang),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = _selectedFilter == i;
          return ChoiceChip(
            label: Text(
              filters[i],
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : _C.textDark),
              ),
            ),
            selected: isSelected,
            selectedColor: isDark ? const Color(0xFF2563EB) : _C.navy,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            side: BorderSide(
              color: isSelected
                  ? (isDark ? const Color(0xFF2563EB) : _C.navy)
                  : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE4E9F2)),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            showCheckmark: false,
            onSelected: (_) => setState(() => _selectedFilter = i),
          );
        },
      ),
    );
  }
}

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
                      AppStrings.get('outages_screen_title', lang),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
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
                      Icons.power_off_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48, top: 4),
                child: Text(
                  AppStrings.get('outages_screen_sub', lang),
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

class _OutageCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lang;
  const _OutageCard({required this.data, required this.lang});

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'su':
        return _C.water;
      case 'elektrik':
        return _C.electric;
      case 'gaz':
      case 'dogalgaz':
        return _C.gas;
      default:
        return _C.navy;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'su':
        return Icons.water_drop_rounded;
      case 'elektrik':
        return Icons.bolt_rounded;
      case 'gaz':
      case 'dogalgaz':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.power_off_rounded;
    }
  }

  String _formatStatus(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('devam') || lower.contains('progress')) {
      return AppStrings.get('status_ongoing', lang);
    }
    if (lower.contains('plan') || lower.contains('planlı')) {
      return AppStrings.get('status_planned', lang);
    }
    if (lower.contains('tamam') || lower.contains('complete')) {
      return AppStrings.get('status_completed', lang);
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final type = (data['type'] ?? '').toString();
    final color = _getTypeColor(type);
    final icon = _getTypeIcon(type);
    final statusText = _formatStatus((data['status'] ?? '').toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE4E9F2),
        ),
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
                  color: color.withAlpha(isDark ? 50 : 30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? '',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : _C.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data['provider'] ?? ''}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF332010)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _C.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : Colors.grey.withAlpha(35),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 16,
                color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data['neighborhood'] ?? '',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFFCBD5E1) : _C.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                '${data['startDate'] ?? '-'}  ➔  ${data['endDate'] ?? '-'}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

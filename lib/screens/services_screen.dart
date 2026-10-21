import 'auth_guard.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_strings.dart';
import '../features/ebelediye/presentation/ebelediye_screen.dart';
import '../features/news/municipal_news_screen.dart';
import '../features/pati/presentation/gebze_pati_screen.dart';
import '../features/pharmacy/presentation/pharmacies_screen.dart';
import '../features/weather/presentation/weather_screen.dart';
import 'emergency_screen.dart';
import 'outages_screen.dart';
import 'soz_sende_screen.dart';
import 'neighborhood_screen.dart';
import '../features/parking/presentation/parking_screen.dart';
import '../features/chatbot/chatbot.dart';

/// Gebze Belediyesi - Hizmetler Ekranı
/// Dosya yolu: lib/screens/services_screen.dart

class _C {
  static const navy = Color(0xFF0A2A66);
  static const navyDeep = Color(0xFF061B45);
  static const orange = Color(0xFFFF7A00);
  static const bg = Color(0xFFF1F5FD);
  static const textDark = Color(0xFF0A1F44);
  static const textMuted = Color(0xFF5F6F8A);
  static const danger = Color(0xFFDC2626);
  static const dangerDark = Color(0xFFB91C1C);

  static const orangeGradient = [Color(0xFFFFA11F), Color(0xFFFF6A00)];
  static const navyGradient = [Color(0xFF1E5BC6), Color(0xFF0A2A66)];
  static const dangerGradient = [danger, dangerDark];
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

class _ServiceData {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  const _ServiceData(
    this.id,
    this.title,
    this.subtitle,
    this.icon,
    this.gradient,
  );
}

class ServicesScreen extends ConsumerStatefulWidget {
  /// Alt menüde başka bir sekmeye geçilmek istendiğinde çağrılır.
  /// (0: Ana Sayfa, 1: Rehber, 2: Bildir, 3: Hizmetler, 4: Profil)
  final ValueChanged<int>? onNavTap;

  /// Bir hizmet kartına dokunulduğunda çağrılır. id: 'kesintiler', 'otopark' ...
  final ValueChanged<String>? onServiceTap;

  const ServicesScreen({super.key, this.onNavTap, this.onServiceTap});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  _ServiceData _getEmergencyData(String lang) => _ServiceData(
    'acil_durum',
    AppStrings.get('service_emergency', lang),
    AppStrings.get('service_emergency_sub', lang),
    Icons.emergency_rounded,
    _C.dangerGradient,
  );

  List<_ServiceData> _getServices(String lang) => [
    _ServiceData(
      'kesintiler',
      AppStrings.get('service_outages', lang),
      AppStrings.get('service_outages_sub', lang),
      Icons.power_off_rounded,
      _C.navyGradient,
    ),
    _ServiceData(
      'otopark',
      AppStrings.get('service_parking', lang),
      AppStrings.get('service_parking_sub', lang),
      Icons.local_parking_rounded,
      _C.navyGradient,
    ),
    _ServiceData(
      'soz_sende',
      AppStrings.get('service_soz_sende', lang),
      AppStrings.get('service_soz_sende_sub', lang),
      Icons.record_voice_over_rounded,
      _C.navyGradient,
    ),
    _ServiceData(
      'gebze_pati',
      AppStrings.get('service_pati', lang),
      AppStrings.get('service_pati_sub', lang),
      Icons.pets_rounded,
      _C.navyGradient,
    ),
    _ServiceData(
      'nobetci_eczane',
      AppStrings.get('service_pharmacy', lang),
      AppStrings.get('service_pharmacy_sub', lang),
      Icons.local_pharmacy_rounded,
      _C.navyGradient,
    ),
    _ServiceData(
      'hava_durumu',
      AppStrings.get('service_weather', lang),
      AppStrings.get('service_weather_sub', lang),
      Icons.wb_cloudy_rounded,
      _C.navyGradient,
    ),
    _ServiceData(
      'mahallemde',
      AppStrings.get('service_neighborhood', lang),
      AppStrings.get('service_neighborhood_sub', lang),
      Icons.location_city_rounded,
      _C.navyGradient,
    ),
    _ServiceData(
      'e_belediye',
      AppStrings.get('service_ebelediye', lang),
      AppStrings.get('service_ebelediye_sub', lang),
      Icons.account_balance_rounded,
      _C.navyGradient,
    ),
    _ServiceData(
      'asistan_bot',
      AppStrings.get('service_assistant', lang),
      AppStrings.get('service_assistant_sub', lang),
      Icons.smart_toy_rounded,
      _C.navyGradient,
    ),
    _ServiceData(
      'haberler',
      AppStrings.get('service_news', lang),
      AppStrings.get('service_news_sub', lang),
      Icons.menu_book_rounded,
      _C.navyGradient,
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_ServiceData> _filter(List<_ServiceData> services) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return services;
    return services
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              s.subtitle.toLowerCase().contains(q),
        )
        .toList();
  }

  void _open(_ServiceData s, String lang) {
    if (s.id == 'acil_durum') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const EmergencyScreen()));
      return;
    }
    if (s.id == 'kesintiler') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const OutagesScreen()));
      return;
    }
    if (s.id == 'soz_sende') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const SozSendeScreen()));
      return;
    }
    if (s.id == 'nobetci_eczane') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const PharmaciesScreen()));
      return;
    }
    if (s.id == 'hava_durumu') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const WeatherScreen()));
      return;
    }
    if (s.id == 'haberler') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const MunicipalNewsScreen()),
      );
      return;
    }
    if (s.id == 'gebze_pati') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const GebzePatiScreen()));
      return;
    }
    if (s.id == 'otopark') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const ParkingScreen()));
      return;
    }
    if (s.id == 'e_belediye') {
      if (!requireLogin(context, ref)) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const EBelediyeScreen()));
      return;
    }
    if (s.id == 'mahallemde') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const NeighborhoodScreen()),
      );
      return;
    }
    if (s.id == 'asistan_bot') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ChatbotScreen(isMini: false),
        ),
      );
      return;
    }

    if (widget.onServiceTap != null) {
      widget.onServiceTap!(s.id);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${s.title} ${AppStrings.get('coming_soon', lang)}'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final base = Theme.of(context);
    final isDark = base.brightness == Brightness.dark;

    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(
          fontFamily: _kBodyFont,
          fontFamilyFallback: _kBodyFontFallback,
          bodyColor: isDark ? Colors.white : const Color(0xFF0A1F44),
          displayColor: isDark ? Colors.white : const Color(0xFF0A1F44),
        ),
      ),
      child: _buildScreen(context, lang),
    );
  }

  Widget _buildScreen(BuildContext context, String lang) {
    final emergency = _getEmergencyData(lang);
    final allServices = _getServices(lang);
    final items = _filter(allServices);

    final showEmergency =
        _query.trim().isEmpty ||
        emergency.title.toLowerCase().contains(_query.trim().toLowerCase());

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : _C.bg,
        body: Column(
          children: [
            _Header(
              controller: _searchCtrl,
              lang: lang,
              onChanged: (v) => setState(() => _query = v),
            ),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  if (showEmergency) ...[
                    _EmergencyCard(
                      data: emergency,
                      onTap: () => _open(emergency, lang),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (items.isEmpty && !showEmergency)
                    _EmptyState(lang: lang)
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            mainAxisExtent: 158,
                          ),
                      itemBuilder: (_, i) => _ServiceCard(
                        data: items[i],
                        onTap: () => _open(items[i], lang),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          index: 3,
          lang: lang,
          onTap: (i) => widget.onNavTap?.call(i),
        ),
      ),
    );
  }
}

// ───────────────────────── Üst Başlık ─────────────────────────

class _Header extends StatelessWidget {
  final TextEditingController controller;
  final String lang;
  final ValueChanged<String> onChanged;
  const _Header({
    required this.controller,
    required this.lang,
    required this.onChanged,
  });

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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _C.orangeGradient,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('services_screen_title', lang),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.get('services_screen_subtitle', lang),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: 56,
                height: 3,
                margin: const EdgeInsets.only(top: 10, bottom: 14),
                decoration: BoxDecoration(
                  color: _C.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Builder(
                builder: (context) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isDark
                          ? Border.all(color: const Color(0xFF334155))
                          : null,
                    ),
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : _C.textDark,
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        fillColor: Colors.transparent,
                        hintText: AppStrings.get('search_services_hint', lang),
                        hintStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : _C.textMuted,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
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
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Acil Durum Kartı ─────────────────────────

class _EmergencyCard extends StatelessWidget {
  final _ServiceData data;
  final VoidCallback onTap;
  const _EmergencyCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: data.gradient,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _C.dangerDark.withValues(alpha: 0.16),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(45),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Hizmet Kartı ─────────────────────────

class _ServiceCard extends StatelessWidget {
  final _ServiceData data;
  final VoidCallback onTap;
  const _ServiceCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: isDark ? 0 : 2,
      shadowColor: _C.navy.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isDark
            ? const BorderSide(color: Color(0xFF334155))
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: data.gradient,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : _C.textDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.25,
                  color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Boş Durum ─────────────────────────

class _EmptyState extends StatelessWidget {
  final String lang;
  const _EmptyState({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 54, color: _C.textMuted),
            const SizedBox(height: 12),
            Text(
              AppStrings.get('no_services_found', lang),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _C.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Alt Menü ─────────────────────────

class _BottomNav extends StatelessWidget {
  final int index;
  final String lang;
  final ValueChanged<int> onTap;
  const _BottomNav({
    required this.index,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      _NavItem(AppStrings.get('nav_home', lang), Icons.home_rounded),
      _NavItem(AppStrings.get('nav_guide', lang), Icons.explore_outlined),
      _NavItem(AppStrings.get('nav_report', lang), Icons.photo_camera_outlined),
      _NavItem(AppStrings.get('nav_services', lang), Icons.grid_view_rounded),
      _NavItem(
        AppStrings.get('nav_profile', lang),
        Icons.person_outline_rounded,
      ),
    ];

    return Material(
      color: _C.navyDeep,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      elevation: 16,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[i].icon,
                          size: 28,
                          color: i == index ? _C.orange : Colors.white70,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].label,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: i == index
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: i == index ? _C.orange : Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 64,
                          height: 3,
                          decoration: BoxDecoration(
                            color: i == index ? _C.orange : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
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

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

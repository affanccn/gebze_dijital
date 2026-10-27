import 'auth_guard.dart';
import 'auth_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/parking/presentation/parking_screen.dart';
import '../core/localization/app_strings.dart';
import '../features/ebelediye/presentation/ebelediye_screen.dart';
import '../features/news/municipal_news_screen.dart';
import '../features/news/widgets/municipal_news_list.dart';
import '../features/weather/presentation/weather_screen.dart';
import '../features/weather/services/weather_provider.dart';
import 'guide_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'services_screen.dart';
import 'neighborhood_screen.dart';
import 'notifications_screen.dart';
import '../core/theme/theme_provider.dart';
import '../core/services/events_service.dart';

/// Gebze Belediyesi - Ana Ekran
/// Dosya yolu: lib/screens/guest_home_screen.dart

class _C {
  // Gebze Belediyesi teması: lacivert + turuncu
  static const navy = Color(0xFF0A2A66);
  static const navyDeep = Color(0xFF061B45);
  static const orange = Color(0xFFFF7A00);
  static const bg = Color(0xFFF1F5FD);
  static const textDark = Color(0xFF0A1F44);
  static const textMuted = Color(0xFF5F6F8A);
  static const danger = Color(0xFFE5231B);

  static const orangeGradient = [Color(0xFFFFA11F), Color(0xFFFF6A00)];
  static const navyGradient = [Color(0xFF1E5BC6), Color(0xFF0A2A66)];
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

List<BoxShadow> _softShadow() => [
  BoxShadow(
    color: const Color(0xFF0A2A66).withAlpha(28),
    blurRadius: 18,
    offset: const Offset(0, 6),
  ),
];

class GuestHomeScreen extends ConsumerStatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  ConsumerState<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends ConsumerState<GuestHomeScreen> {
  // Hero görseli: proje kökündeki gorsel/ klasörü (pubspec.yaml'da tanımlı olmalı).
  static const String _heroAsset = 'gorsel/gebze_gorsel.jpg';

  int _navIndex = 0;
  double? _heroAspect; // görselin genişlik / yükseklik oranı

  @override
  void initState() {
    super.initState();
    _resolveHeroAspect();
  }

  void _resolveHeroAspect() {
    final stream = AssetImage(_heroAsset).resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      final aspect = info.image.width / info.image.height;
      if (mounted) setState(() => _heroAspect = aspect);
      stream.removeListener(listener);
    }, onError: (_, _) => stream.removeListener(listener));
    stream.addListener(listener);
  }

  List<_QuickActionData> _getQuickActions(String lang) {
    return [
      _QuickActionData(
        AppStrings.get('qa_places', lang),
        Icons.map_rounded,
        _C.orangeGradient,
        onTap: () => _openGuide(initialTab: 1),
      ),
      _QuickActionData(
        AppStrings.get('qa_food', lang),
        Icons.restaurant_rounded,
        _C.navyGradient,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const GuideCategoryScreen(categoryId: 'lokantalar'),
          ),
        ),
      ),
      _QuickActionData(
        AppStrings.get('qa_ebel', lang),
        Icons.account_balance_rounded,
        _C.orangeGradient,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const EBelediyeScreen())),
      ),
      _QuickActionData(
        AppStrings.get('qa_report', lang),
        Icons.report_problem_rounded,
        _C.navyGradient,
        onTap: () => _handleNav(2),
      ),
      _QuickActionData(
        AppStrings.get('qa_parking', lang),
        Icons.local_parking_rounded,
        _C.orangeGradient,
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ParkingScreen())),
      ),
      _QuickActionData(
        AppStrings.get('qa_neighborhood', lang),
        Icons.location_city_rounded,
        _C.navyGradient,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NeighborhoodScreen())),
      ),
    ];
  }

  List<_RowData> _getHistoricPlaces(String lang) => [
    _RowData(
      AppStrings.get('hp_eskihisar_title', lang),
      AppStrings.get('hp_eskihisar_sub', lang),
      Icons.castle_rounded,
      imageAsset: 'gorsel/tarihi_yerler/eskale.jpg',
      onTap: () => _openGuide(initialTab: 1),
    ),
    _RowData(
      AppStrings.get('hp_cmp_title', lang),
      AppStrings.get('hp_cmp_sub', lang),
      Icons.mosque_rounded,
      imageAsset: 'gorsel/tarihi_yerler/cmpasa.jpg',
      onTap: () => _openGuide(initialTab: 1),
    ),
    _RowData(
      AppStrings.get('hp_hannibal_title', lang),
      AppStrings.get('hp_hannibal_sub', lang),
      Icons.account_balance_rounded,
      imageAsset: 'gorsel/tarihi_yerler/anibal.jpg',
      onTap: () => _openGuide(initialTab: 1),
    ),
  ];

  /// Rehberi açar. initialTab: 0 = Kurumsal Hizmetler, 1 = Gebze'yi Keşfet
  void _openGuide({int initialTab = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuideScreen(
          initialTab: initialTab,
          onNavTap: (j) {
            Navigator.of(context).pop();
            if (j != 0 && j != 1) _handleNav(j);
          },
        ),
      ),
    );
  }

  /// Alt menü yönlendirmesi
  void _handleNav(int i) {
    if (i == 4 && !requireLogin(context, ref)) return;
    if (i == 1) {
      _openGuide();
    } else if (i == 2) {
      final isLoggedIn = ref.read(isLoggedInProvider);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReportScreen(
            isGuest: !isLoggedIn,
            onNavTap: (j) {
              Navigator.of(context).pop();
              if (j != 0 && j != 2) _handleNav(j);
            },
          ),
        ),
      );
    } else if (i == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ServicesScreen(
            onNavTap: (j) {
              Navigator.of(context).pop();
              if (j != 0 && j != 3) _handleNav(j);
            },
          ),
        ),
      );
    } else if (i == 4) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            onNavTap: (j) {
              Navigator.of(context).pop();
              if (j != 0 && j != 4) _handleNav(j);
            },
          ),
        ),
      );
    } else {
      setState(() => _navIndex = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final base = Theme.of(context);
    final isDark = context.isDark;

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
    final size = MediaQuery.of(context).size;
    final heroH = _heroAspect != null
        ? (size.width / _heroAspect!).clamp(280.0, 480.0)
        : (size.height * 0.42).clamp(330.0, 410.0);
    const overlap = 32.0;

    final quickActions = _getQuickActions(lang);
    final historicPlaces = _getHistoricPlaces(lang);

    final isDark = context.isDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : _C.bg,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Stack(
            children: [
              // Hero arka planı
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: heroH,
                child: _HeroBackground(asset: _heroAsset),
              ),

              // Hero içeriği + beyaz içerik paneli
              Column(
                children: [
                  SizedBox(
                    height: heroH - overlap,
                    child: _HeroContent(lang: lang),
                  ),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : _C.bg,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(overlap),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 52, 16, 110),
                    child: Column(
                      children: [
                        _QuickActionsCard(items: quickActions),
                        const SizedBox(height: 16),
                        _EventsSection(lang: lang),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: AppStrings.get('historic_places_title', lang),
                          seeAllText: AppStrings.get('see_all', lang),
                          icon: Icons.account_balance_rounded,
                          iconColor: _C.navy,
                          rows: historicPlaces,
                          onSeeAll: () => _openGuide(initialTab: 1),
                        ),
                        const SizedBox(height: 16),
                        _NewsSection(lang: lang),
                      ],
                    ),
                  ),
                ],
              ),

              // Hava durumu kartı (hero ile panel arasında)
              Positioned(
                left: 16,
                top: heroH - overlap - 44,
                child: _WeatherPill(width: size.width * 0.66, lang: lang),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _BottomNav(
          index: _navIndex,
          lang: lang,
          onTap: _handleNav,
        ),
      ),
    );
  }
}

// ───────────────────────── Hero ─────────────────────────

class _HeroBackground extends StatelessWidget {
  final String? asset;
  const _HeroBackground({this.asset});

  @override
  Widget build(BuildContext context) {
    if (asset != null) {
      return ClipRect(
        child: ColoredBox(
          color: _C.navyDeep,
          child: Image.asset(
            asset!,
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => const _HeroPlaceholder(),
          ),
        ),
      );
    }
    return const _HeroPlaceholder();
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E6FE0),
            Color(0xFF8CC4FF),
            Color(0xFFFFB347),
            Color(0xFFFF7A00),
          ],
          stops: [0.0, 0.4, 0.65, 1.0],
        ),
      ),
      child: const Align(
        alignment: Alignment(0.7, -0.1),
        child: Text(
          'GEBZE',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
            letterSpacing: 4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  final String lang;
  const _HeroContent({required this.lang});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _Logo(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.get('welcome_gebze', lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : _C.navy,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                  child: const _BellIcon(),
                ),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 74,
              child: Transform.rotate(
                angle: -0.17,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppStrings.get('better_gebze', lang),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 21,
                        height: 1.15,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black38, blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 130,
                      height: 3,
                      decoration: BoxDecoration(
                        color: _C.orange,
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
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Image.asset(
        'gorsel/gebze_logo.png',
        height: 58,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _LogoFallback(),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.account_balance_rounded, color: _C.orange, size: 38),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GEBZE',
              style: TextStyle(
                fontSize: 26,
                height: 1,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : _C.navy,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'BELEDİYESİ',
              style: TextStyle(
                fontSize: 13,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : _C.navy,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BellIcon extends ConsumerWidget {
  const _BellIcon();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 32,
          ),
          if (unreadCount > 0)
            Positioned(
              top: 3,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                decoration: BoxDecoration(
                  color: _C.danger,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _C.danger.withAlpha(120),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── Hava Durumu ─────────────────────────

class _WeatherPill extends ConsumerWidget {
  final double width;
  final String lang;
  const _WeatherPill({required this.width, required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsyncValue = ref.watch(weatherProvider);

    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const WeatherScreen()));
      },
      child: Container(
        width: width.clamp(250.0, 360.0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xF20A2A66),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white24),
          boxShadow: _softShadow(),
        ),
        child: weatherAsyncValue.when(
          data: (weatherInfo) {
            if (weatherInfo == null) {
              return _buildPlaceholder();
            }

            final temp = '${weatherInfo.current.tempC.round()}°';
            final condition = AppStrings.translateWeatherCondition(
              weatherInfo.current.condition,
              lang,
            );

            String iconUrl = weatherInfo.current.icon;
            if (iconUrl.startsWith('//')) {
              iconUrl = 'https:$iconUrl';
            }

            return Row(
              children: [
                SizedBox(
                  width: 46,
                  height: 40,
                  child: iconUrl.isNotEmpty
                      ? Image.network(
                          iconUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.cloud_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        )
                      : const Icon(
                          Icons.cloud_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      temp,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      condition,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white24,
                ),
                const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.get('gebze_city', lang),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        AppStrings.get('current_weather_pill', lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => _buildLoading(),
          error: (_, _) => _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Row(
      children: [
        const SizedBox(
          width: 46,
          height: 40,
          child: Icon(Icons.cloud_off, color: Colors.white, size: 36),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '--°',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppStrings.get('failed_to_load', lang),
              style: const TextStyle(color: Colors.white, fontSize: 11.5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(
          AppStrings.get('loading', lang),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}

// ───────────────────────── Hızlı İşlemler ─────────────────────────

class _QuickActionData {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onTap;
  const _QuickActionData(this.label, this.icon, this.gradient, {this.onTap});
}

class _QuickActionsCard extends StatelessWidget {
  final List<_QuickActionData> items;
  const _QuickActionsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
        boxShadow: isDark ? [] : _softShadow(),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: item.onTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: item.gradient,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: item.gradient.last.withAlpha(90),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 28),
                      child: Text(
                        item.label,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.0,
                          letterSpacing: -0.2,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : _C.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── Bölüm Kartları ─────────────────────────

class _RowData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? imageAsset;
  final String? imageUrl;
  final VoidCallback? onTap;
  const _RowData(
    this.title,
    this.subtitle,
    this.icon, {
    this.imageAsset,
    this.imageUrl,
    this.onTap,
  });
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String seeAllText;
  final IconData icon;
  final Color iconColor;
  final List<_RowData> rows;
  final VoidCallback? onSeeAll;

  const _SectionCard({
    required this.title,
    required this.seeAllText,
    required this.icon,
    required this.iconColor,
    required this.rows,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
        boxShadow: isDark ? [] : _softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : _C.textDark,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              InkWell(
                onTap: onSeeAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      seeAllText,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _C.orange,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: _C.orange,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (int i = 0; i < rows.length; i++) ...[
            _SectionRow(data: rows[i]),
            if (i != rows.length - 1)
              Divider(
                height: 1,
                color: isDark
                    ? const Color(0xFF334155)
                    : Colors.grey.withAlpha(40),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final _RowData data;
  const _SectionRow({required this.data});

  Widget _buildThumbnail(_RowData data) {
    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F6FDB), Color(0xFF0A2A66)],
        ),
      ),
      child: Icon(data.icon, color: Colors.white, size: 26),
    );

    if (data.imageUrl != null && data.imageUrl!.trim().isNotEmpty) {
      return Image.network(
        data.imageUrl!.trim(),
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFFEEF4FF),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }

    if (data.imageAsset != null && data.imageAsset!.trim().isNotEmpty) {
      return Image.asset(
        data.imageAsset!.trim(),
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildThumbnail(data),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : _C.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
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

// ───────────────────────── Etkinlikler (Firestore) ─────────────────────────

class _EventsSection extends ConsumerWidget {
  final String lang;
  const _EventsSection({required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final eventsAsync = ref.watch(eventsListProvider);

    void navigateToEvents() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              const GuideCategoryScreen(categoryId: 'etkinlikler'),
        ),
      );
    }

    return eventsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(
        child: Text(
          '${AppStrings.get('error_occurred', lang)}: $e',
        ),
      ),
      data: (allEvents) {
        final upcoming = allEvents.where((e) {
          final d = (e['date'] ?? '').toString();
          return d.isNotEmpty && d.compareTo(today) >= 0;
        }).toList()
          ..sort((a, b) => (a['date'] ?? '').toString().compareTo((b['date'] ?? '').toString()));
        final displayUpcoming = upcoming.take(3).toList();

        final List<Map<String, dynamic>> targetList;
        if (displayUpcoming.isNotEmpty) {
          targetList = displayUpcoming;
        } else if (allEvents.isNotEmpty) {
          final latest = allEvents.toList()
            ..sort((a, b) => (b['date'] ?? '').toString().compareTo((a['date'] ?? '').toString()));
          targetList = latest.take(3).toList();
        } else {
          targetList = [];
        }

        final List<_RowData> rows;
        if (targetList.isEmpty) {
          rows = [
            _RowData(
              'Tafiti Çölde Macera',
              'Gebze Kültür Merkezi • 31 Ekim • 13:00',
              Icons.event_rounded,
              onTap: navigateToEvents,
            ),
            _RowData(
              'Neşeli Orman Dostları',
              'Gebze Kültür Merkezi • 1 Kasım • 13:00',
              Icons.event_rounded,
              onTap: navigateToEvents,
            ),
            _RowData(
              'Prof. Dr. Nurullah Genç - Başarı ve Karakter',
              'Gebze Kültür Merkezi • 1 Kasım • 19:30',
              Icons.event_rounded,
              onTap: navigateToEvents,
            ),
          ];
        } else {
          rows = targetList.map((m) {
            final title = (m['title'] ?? m['name'] ?? '').toString();
            var subtitle = (m['subtitle'] ?? '').toString();
            if (subtitle.isEmpty) {
              final loc = (m['location'] ?? m['address'] ?? 'Gebze').toString();
              final date = (m['formattedDate'] ?? m['date'] ?? '').toString();
              final time = (m['time'] ?? '').toString();
              subtitle = [loc, date, time].where((s) => s.isNotEmpty).join(' • ');
            }
            final img = (m['imageUrl'] ?? m['image'] ?? '').toString().trim();
            return _RowData(
              title,
              subtitle,
              Icons.event_rounded,
              imageUrl: img.isNotEmpty ? img : null,
              onTap: navigateToEvents,
            );
          }).toList();
        }

        return _SectionCard(
          title: AppStrings.get('events_title', lang),
          seeAllText: AppStrings.get('see_all', lang),
          icon: Icons.event_available_rounded,
          iconColor: _C.orange,
          rows: rows,
          onSeeAll: navigateToEvents,
        );
      },
    );
  }
}

// ───────────────────────── Haberler (Firestore) ─────────────────────────

class _NewsSection extends StatelessWidget {
  final String lang;
  const _NewsSection({required this.lang});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.get('news_title', lang),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : _C.textDark,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MunicipalNewsScreen(),
                    ),
                  );
                },
                child: Text(
                  AppStrings.get('see_all', lang),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF38BDF8) : _C.navy,
                  ),
                ),
              ),
            ],
          ),
        ),
        const MunicipalNewsList(itemLimit: 3, isHorizontal: true),
      ],
    );
  }
}
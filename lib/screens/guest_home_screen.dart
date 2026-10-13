import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_strings.dart';
import '../features/ebelediye/presentation/ebelediye_screen.dart';
import '../features/news/municipal_news_screen.dart';
import '../features/news/widgets/municipal_news_list.dart';
import '../features/weather/presentation/weather_screen.dart';
import '../features/weather/services/weather_provider.dart';
import 'emergency_screen.dart';
import 'guide_screen.dart';
import 'profile_screen.dart';
import 'services_screen.dart';
import 'soz_sende_screen.dart';

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
  static const String? _heroAsset = 'gorsel/gebze_gorsel.jpg';

  int _navIndex = 0;
  double? _heroAspect; // görselin genişlik / yükseklik oranı

  @override
  void initState() {
    super.initState();
    _resolveHeroAspect();
  }

  void _resolveHeroAspect() {
    final asset = _heroAsset;
    if (asset == null) return;
    final stream = AssetImage(asset).resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      final aspect = info.image.width / info.image.height;
      if (mounted) setState(() => _heroAspect = aspect);
      stream.removeListener(listener);
    }, onError: (_, __) => stream.removeListener(listener));
    stream.addListener(listener);
  }

  List<_QuickActionData> _getQuickActions(String lang) => [
        _QuickActionData(
          AppStrings.get('qa_places', lang),
          Icons.map_rounded,
          _C.orangeGradient,
          onTap: () => _handleNav(1),
        ),
        _QuickActionData(
          AppStrings.get('qa_food', lang),
          Icons.restaurant_rounded,
          _C.navyGradient,
          onTap: () => _handleNav(1),
        ),
        _QuickActionData(
          AppStrings.get('qa_ebel', lang),
          Icons.account_balance_rounded,
          _C.orangeGradient,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EBelediyeScreen()),
          ),
        ),
        _QuickActionData(
          AppStrings.get('qa_complaint', lang),
          Icons.report_problem_rounded,
          _C.navyGradient,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SozSendeScreen()),
          ),
        ),
        _QuickActionData(
          AppStrings.get('qa_parking', lang),
          Icons.local_parking_rounded,
          _C.orangeGradient,
          onTap: () => _handleNav(3),
        ),
      ];

  List<_RowData> _getHistoricPlaces(String lang) => [
        _RowData(
          AppStrings.get('hp_eskihisar_title', lang),
          AppStrings.get('hp_eskihisar_sub', lang),
          Icons.castle_rounded,
          onTap: () => _handleNav(1),
        ),
        _RowData(
          AppStrings.get('hp_cmp_title', lang),
          AppStrings.get('hp_cmp_sub', lang),
          Icons.mosque_rounded,
          onTap: () => _handleNav(1),
        ),
        _RowData(
          AppStrings.get('hp_hannibal_title', lang),
          AppStrings.get('hp_hannibal_sub', lang),
          Icons.account_balance_rounded,
          onTap: () => _handleNav(1),
        ),
      ];

  /// Alt menü yönlendirmesi
  void _handleNav(int i) {
    if (i == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GuideScreen(
            onNavTap: (j) {
              Navigator.of(context).pop();
              if (j != 0 && j != 1) _handleNav(j);
            },
          ),
        ),
      );
    } else if (i == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SozSendeScreen()),
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

    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(
          fontFamily: _kBodyFont,
          fontFamilyFallback: _kBodyFontFallback,
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _C.bg,
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
                    decoration: const BoxDecoration(
                      color: _C.bg,
                      borderRadius: BorderRadius.vertical(
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
                          onSeeAll: () => _handleNav(1),
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
                child: _WeatherPill(
                  width: size.width * 0.66,
                  lang: lang,
                ),
              ),
            ],
          ),
        ),

        // Acil durum butonu (sağ altta sabit)
        floatingActionButton: SizedBox(
          width: 78,
          height: 78,
          child: FloatingActionButton(
            heroTag: 'emergency_fab',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EmergencyScreen(),
                ),
              );
            },
            backgroundColor: _C.danger,
            foregroundColor: Colors.white,
            elevation: 8,
            shape: const CircleBorder(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emergency_rounded, size: 28),
                const SizedBox(height: 2),
                Text(
                  AppStrings.get('emergency_btn', lang),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
            errorBuilder: (_, __, ___) => const _HeroPlaceholder(),
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
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: _C.navy,
                    ),
                  ),
                ),
                GestureDetector(onTap: () {}, child: const _BellIcon()),
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
        errorBuilder: (_, __, ___) => const _LogoFallback(),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.account_balance_rounded, color: _C.orange, size: 38),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GEBZE',
              style: TextStyle(
                fontSize: 26,
                height: 1,
                fontWeight: FontWeight.w900,
                color: _C.navy,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'BELEDİYESİ',
              style: TextStyle(
                fontSize: 13,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: _C.navy,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BellIcon extends StatelessWidget {
  const _BellIcon();

  @override
  Widget build(BuildContext context) {
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
          Positioned(
            top: 4,
            right: 6,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: _C.danger,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
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
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const WeatherScreen()),
        );
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
                          errorBuilder: (_, __, ___) => const Icon(
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
          error: (_, __) => _buildPlaceholder(),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: _softShadow(),
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
                        style: const TextStyle(
                          fontSize: 9.5,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: _C.textDark,
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
  final VoidCallback? onTap;
  const _RowData(
    this.title,
    this.subtitle,
    this.icon, {
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: _softShadow(),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _C.textDark,
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
              Divider(height: 1, color: Colors.grey.withAlpha(40)),
          ],
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final _RowData data;
  const _SectionRow({required this.data});

  @override
  Widget build(BuildContext context) {
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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2F6FDB), Color(0xFF0A2A66)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(data.icon, color: Colors.white, size: 26),
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
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: _C.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: _C.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _C.textMuted),
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
      _NavItem(AppStrings.get('nav_profile', lang), Icons.person_outline_rounded),
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

class _EventsSection extends StatelessWidget {
  final String lang;
  const _EventsSection({required this.lang});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .orderBy('date')
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text('${AppStrings.get('error_occurred', lang)}: ${snap.error}'),
          );
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          );
        }
        final rows = snap.data!.docs.map((d) {
          final m = d.data();
          return _RowData(
            m['title'] ?? '',
            m['subtitle'] ?? '',
            Icons.event_rounded,
          );
        }).toList();

        return _SectionCard(
          title: AppStrings.get('events_title', lang),
          seeAllText: AppStrings.get('see_all', lang),
          icon: Icons.event_available_rounded,
          iconColor: _C.orange,
          rows: rows,
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
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
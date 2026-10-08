import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gebze Belediyesi - Ana Ekran
/// Dosya yolu önerisi: lib/screens/guest_home_screen.dart

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

// Bootstrap'teki var(--bs-body-font-family) ile aynı sistem yazı tipi yığını.
// (Flutter'da CSS değişkeni olmadığı için değerleri doğrudan yazıldı.)
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

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  // Hero görseli: proje kökündeki gorsel/ klasörü (pubspec.yaml'da tanımlı olmalı).
  static const String? _heroAsset = 'gorsel/gebze_gorsel.jpg';

  int _navIndex = 0;
  double? _heroAspect; // görselin genişlik / yükseklik oranı

  @override
  void initState() {
    super.initState();
    _resolveHeroAspect();
  }

  // Görselin gerçek oranını okuyup hero yüksekliğini buna göre ayarlar,
  // böylece görsel ekran genişliğine sığar (sağdan/soldan kırpılmaz).
  void _resolveHeroAspect() {
    final asset = _heroAsset;
    if (asset == null) return;
    final stream = AssetImage(asset).resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        final aspect = info.image.width / info.image.height;
        if (mounted) setState(() => _heroAspect = aspect);
        stream.removeListener(listener);
      },
      onError: (_, __) => stream.removeListener(listener),
    );
    stream.addListener(listener);
  }

  static const _quickActions = <_QuickActionData>[
    _QuickActionData('GEZİLECEK YER', Icons.map_rounded, _C.orangeGradient),
    _QuickActionData('YEME İÇME', Icons.restaurant_rounded, _C.navyGradient),
    _QuickActionData('E-BEL', Icons.account_balance_rounded, _C.orangeGradient),
    _QuickActionData('MİSAFİR ŞİKAYET', Icons.report_problem_rounded, _C.navyGradient),
    _QuickActionData('OTOPARK', Icons.local_parking_rounded, _C.orangeGradient),
  ];

  static const _events = <_RowData>[
    _RowData('Gebze Kültür Festivali', '12 Kasım • Gebze Kültür Merkezi', Icons.event_rounded),
    _RowData('Açık Hava Konseri', '15 Kasım • Millet Bahçesi', Icons.music_note_rounded),
    _RowData('Çocuk Tiyatrosu', '19 Kasım • Şehir Tiyatrosu', Icons.theater_comedy_rounded),
  ];

  static const _historicPlaces = <_RowData>[
    _RowData('Eskihisar Kalesi', 'Tarihi kale ve sahil', Icons.castle_rounded),
    _RowData('Çoban Mustafa Paşa Külliyesi', 'Osmanlı dönemi külliye', Icons.mosque_rounded),
    _RowData('Hannibal Anıt Mezarı', 'Antik dönem anıtı', Icons.account_balance_rounded),
  ];

  static const _news = <_RowData>[
    _RowData("Gebze'de Yeni Park Projesi Hizmete Açıldı", '28 Ekim 2026', Icons.article_rounded),
    _RowData('Belediyemizden Öğrencilere Ücretsiz Ulaşım Desteği', '25 Ekim 2026', Icons.article_rounded),
    _RowData('Mustafapaşa Sahil Düzenleme Çalışmaları Başladı', '20 Ekim 2026', Icons.article_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(
          fontFamily: _kBodyFont,
          fontFamilyFallback: _kBodyFontFallback,
        ),
      ),
      child: _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final heroH = _heroAspect != null
        ? (size.width / _heroAspect!).clamp(280.0, 480.0)
        : (size.height * 0.42).clamp(330.0, 410.0);
    const overlap = 32.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
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
                    child: const _HeroContent(),
                  ),
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: _C.bg,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(overlap)),
                    ),
                    // Alt boşluk: acil durum butonunun son kartı kapatmaması için
                    padding: const EdgeInsets.fromLTRB(16, 52, 16, 110),
                    child: Column(
                      children: [
                        _QuickActionsCard(items: _quickActions),
                        const SizedBox(height: 16),
                        const _SectionCard(
                          title: 'YAKLAŞAN ETKİNLİKLER',
                          icon: Icons.event_available_rounded,
                          iconColor: _C.orange,
                          rows: _events,
                        ),
                        const SizedBox(height: 16),
                        const _SectionCard(
                          title: 'TARİHİ YERLER',
                          icon: Icons.account_balance_rounded,
                          iconColor: _C.navy,
                          rows: _historicPlaces,
                        ),
                        const SizedBox(height: 16),
                        const _SectionCard(
                          title: 'HABERLER',
                          icon: Icons.menu_book_rounded,
                          iconColor: _C.orange,
                          rows: _news,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Hava durumu kartı (hero ile panel arasında)
              Positioned(
                left: 16,
                top: heroH - overlap - 44,
                child: _WeatherPill(width: size.width * 0.66),
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
            onPressed: () {},
            backgroundColor: _C.danger,
            foregroundColor: Colors.white,
            elevation: 8,
            shape: const CircleBorder(),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emergency_rounded, size: 28),
                SizedBox(height: 2),
                Text(
                  'ACİL\nDURUM',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, height: 1.05, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        bottomNavigationBar: _BottomNav(
          index: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
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
      // fitWidth: görsel her zaman ekran genişliğine tam oturur (sağ/sol kırpılmaz).
      // Görselin altında boşluk kalırsa lacivert zemin görünür.
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
    // GÖRSEL placeholder: gün batımı tonlarında gradient
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E6FE0), Color(0xFF8CC4FF), Color(0xFFFFB347), Color(0xFFFF7A00)],
          stops: [0.0, 0.4, 0.65, 1.0],
        ),
      ),
      child: const Align(
        alignment: Alignment(0.7, -0.1),
        child: Text(
          'GÖRSEL',
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
  const _HeroContent();

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
                // Karşılama yazısı: logodan bağımsız, logonun sağında
                const Expanded(
                  child: Text(
                    "Gebze'ye\nHoşgeldiniz",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: _C.navy,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
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
                    const Text(
                      'Daha güzel\nbir Gebze için',
                      textAlign: TextAlign.right,
                      style: TextStyle(
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

// Logo dosyası bulunamazsa gösterilen yedek logo
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
          const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 32),
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

class _WeatherPill extends StatelessWidget {
  final double width;
  const _WeatherPill({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width.clamp(250.0, 360.0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xF20A2A66),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
        boxShadow: _softShadow(),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 40,
            child: Stack(
              children: const [
                Positioned(
                  top: 0,
                  right: 2,
                  child: Icon(Icons.wb_sunny_rounded, color: _C.orange, size: 24),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Icon(Icons.cloud_rounded, color: Colors.white, size: 36),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '15°',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Parçalı Bulutlu',
                style: TextStyle(color: Colors.white, fontSize: 11.5),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.white24,
          ),
          const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gebze',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Güncel Hava Durumu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Hızlı İşlemler ─────────────────────────

class _QuickActionData {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  const _QuickActionData(this.label, this.icon, this.gradient);
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
                onTap: () {},
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
                    SizedBox(
                      height: 26,
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
  const _RowData(this.title, this.subtitle, this.icon);
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<_RowData> rows;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.rows,
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
                onTap: () {},
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tümünü Gör',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _C.orange,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, color: _C.orange, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (int i = 0; i < rows.length; i++) ...[
            _SectionRow(data: rows[i]),
            if (i != rows.length - 1) Divider(height: 1, color: Colors.grey.withAlpha(40)),
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
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Görsel placeholder'ı
            Container(
              width: 58,
              height: 58,
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
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  static const _items = <_NavItem>[
    _NavItem('ANA SAYFA', Icons.home_rounded),
    _NavItem('REHBER', Icons.explore_outlined),
    _NavItem('BİLDİR', Icons.photo_camera_outlined),
    _NavItem('HİZMETLER', Icons.grid_view_rounded),
    _NavItem('PROFİL', Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
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
              for (int i = 0; i < _items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _items[i].icon,
                          size: 28,
                          color: i == index ? _C.orange : Colors.white70,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _items[i].label,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: i == index ? FontWeight.w800 : FontWeight.w500,
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
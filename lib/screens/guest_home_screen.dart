import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gebze Belediyesi - Ana Ekran
/// Dosya yolu önerisi: lib/screens/guest_home_screen.dart

class _C {
  static const navy = Color(0xFF0F2547);
  static const blue = Color(0xFF1565D8);
  static const orange = Color(0xFFF5A524);
  static const bg = Color(0xFFF2F5FA);
  static const textDark = Color(0xFF14213D);
  static const textMuted = Color(0xFF6B7A8A);
  static const danger = Color(0xFFE53935);
}

List<BoxShadow> _softShadow() => [
      BoxShadow(
        color: const Color(0xFF14213D).withAlpha(22),
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
  // Hero görseli için: assets klasörüne ekleyip yolunu yazın,
  // örn: 'assets/images/gebze_hero.jpg' (pubspec.yaml'a da eklemeyi unutmayın).
  static const String? _heroAsset = null;

  int _navIndex = 0;

  static const _quickActions = <_QuickActionData>[
    _QuickActionData('GEZİLECEK YERLER', Icons.map_rounded, Color(0xFF1565D8), Color(0xFFE4EEFC)),
    _QuickActionData('YEME İÇME', Icons.restaurant_rounded, Color(0xFFF59E0B), Color(0xFFFFF0DC)),
    _QuickActionData('E-BEL', Icons.account_balance_rounded, Color(0xFF3949AB), Color(0xFFE8EAF8)),
    _QuickActionData('MİSAFİR ŞİKAYET', Icons.report_problem_rounded, Color(0xFFE53935), Color(0xFFFDE8E8)),
    _QuickActionData('OTOPARK', Icons.local_parking_rounded, Color(0xFF00897B), Color(0xFFE0F4F1)),
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
    final size = MediaQuery.of(context).size;
    final heroH = (size.height * 0.42).clamp(330.0, 410.0);
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
                          iconColor: _C.blue,
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
      return Image.asset(asset!, fit: BoxFit.cover);
    }
    // GÖRSEL placeholder: gün batımı tonlarında gradient
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4E8FCB), Color(0xFFBFD8EE), Color(0xFFF7C99B), Color(0xFF5E7FA3)],
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _Logo(),
                    GestureDetector(
                      onTap: () {},
                      child: const _BellIcon(),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  "Gebze'ye\nHoşgeldiniz",
                  style: TextStyle(
                    fontSize: 30,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: _C.navy,
                  ),
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
        color: const Color(0xEB0F2A4A),
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
  final Color color;
  final Color background;
  const _QuickActionData(this.label, this.icon, this.color, this.background);
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
                        color: item.background,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(item.icon, color: item.color, size: 28),
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
                        color: _C.blue,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, color: _C.blue, size: 16),
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
                  colors: [Color(0xFF8FB8DE), Color(0xFF4F7FAE)],
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
      color: _C.navy,
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
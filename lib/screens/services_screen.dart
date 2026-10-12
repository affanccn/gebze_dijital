import 'emergency_screen.dart';
import 'outages_screen.dart';
import 'soz_sende_screen.dart';
import '../features/pharmacy/presentation/pharmacies_screen.dart';
import '../features/weather/presentation/weather_screen.dart';
import '../features/news/municipal_news_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gebze Belediyesi - Hizmetler Ekranı
/// Dosya yolu önerisi: lib/screens/services_screen.dart

class _C {
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

class _ServiceData {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  const _ServiceData(this.id, this.title, this.subtitle, this.icon, this.gradient);
}

class ServicesScreen extends StatefulWidget {
  /// Alt menüde başka bir sekmeye geçilmek istendiğinde çağrılır.
  /// (0: Ana Sayfa, 1: Rehber, 2: Bildir, 3: Hizmetler, 4: Profil)
  final ValueChanged<int>? onNavTap;

  /// Bir hizmet kartına dokunulduğunda çağrılır. id: 'kesintiler', 'otopark' ...
  final ValueChanged<String>? onServiceTap;

  const ServicesScreen({super.key, this.onNavTap, this.onServiceTap});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  // Acil Durum üstte ayrı, büyük kart olarak gösterilir.
  static const _emergency = _ServiceData(
    'acil_durum',
    'ACİL DURUM',
    'Acil numaralar ve tek dokunuşla yardım çağır',
    Icons.emergency_rounded,
    [Color(0xFFFF5A4F), Color(0xFFE5231B)],
  );

  static const _services = <_ServiceData>[
    _ServiceData('kesintiler', 'Kesintiler', 'Su, elektrik ve doğalgaz kesintileri',
        Icons.power_off_rounded, _C.navyGradient),
    _ServiceData('otopark', 'Otopark', 'Boş park yerleri ve ücretler',
        Icons.local_parking_rounded, _C.navyGradient),
    _ServiceData('soz_sende', 'Söz Sende', 'Fikir, öneri ve oylamalar',
        Icons.record_voice_over_rounded, _C.navyGradient),
    _ServiceData('gebze_pati', 'Gebze Pati', 'Sahiplendirme ve sokak hayvanları',
        Icons.pets_rounded, _C.navyGradient),
    _ServiceData('nobetci_eczane', 'Nöbetçi Eczane', 'Bugün nöbetçi olan eczaneler',
        Icons.local_pharmacy_rounded, _C.navyGradient),
    _ServiceData('hava_durumu', 'Hava Durumu', 'Anlık durum ve haftalık tahmin',
        Icons.wb_cloudy_rounded, _C.navyGradient),
    _ServiceData('mahallemde', 'Mahallemde', 'Mahallendeki çalışmalar ve hizmetler',
        Icons.location_city_rounded, _C.navyGradient),
    _ServiceData('e_belediye', 'E-Belediye', 'Borç sorgulama ve online işlemler',
        Icons.account_balance_rounded, _C.navyGradient),
    _ServiceData('asistan_bot', 'AsistanBot', 'Sorularını yapay zekâ ile yanıtla',
        Icons.smart_toy_rounded, _C.navyGradient),
    _ServiceData('haberler', 'Haberler', 'Belediyeden güncel haberler',
        Icons.menu_book_rounded, _C.navyGradient),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_ServiceData> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _services;
    return _services
        .where((s) =>
            s.title.toLowerCase().contains(q) || s.subtitle.toLowerCase().contains(q))
        .toList();
  }

  void _open(_ServiceData s) {
  if (s.id == 'acil_durum') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const EmergencyScreen()),
    );
    return;
  }
  if (s.id == 'kesintiler') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OutagesScreen()),
    );
    return;
  }
    if (s.id == 'soz_sende') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SozSendeScreen()),
    );
  }
  if (s.id == 'nobetci_eczane') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PharmaciesScreen()),
    );
    return;
  }
  if (s.id == 'hava_durumu') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const WeatherScreen()),
    );
    return;
  }
  if (s.id == 'haberler') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MunicipalNewsScreen()),

    );
    return;
  }
  if (widget.onServiceTap != null) {
    widget.onServiceTap!(s.id);
    return;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('${s.title} yakında')));
}

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
    final items = _filtered;
    final showEmergency = _query.trim().isEmpty ||
        _emergency.title.toLowerCase().contains(_query.trim().toLowerCase());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            _Header(controller: _searchCtrl, onChanged: (v) => setState(() => _query = v)),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  if (showEmergency) ...[
                    _EmergencyCard(data: _emergency, onTap: () => _open(_emergency)),
                    const SizedBox(height: 16),
                  ],
                  if (items.isEmpty && !showEmergency)
                    const _EmptyState()
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        mainAxisExtent: 158,
                      ),
                      itemBuilder: (_, i) =>
                          _ServiceCard(data: items[i], onTap: () => _open(items[i])),
                    ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          index: 3,
          onTap: (i) => widget.onNavTap?.call(i),
        ),
      ),
    );
  }
}

// ───────────────────────── Üst Başlık ─────────────────────────

class _Header extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _Header({required this.controller, required this.onChanged});

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
                    child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HİZMETLER',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Gebze Belediyesi dijital hizmetleri',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
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
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 14, color: _C.textDark),
                  decoration: const InputDecoration(
                    hintText: 'Hizmet ara...',
                    hintStyle: TextStyle(color: _C.textMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: _C.textMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 13),
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
                color: _C.danger.withAlpha(80),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(45),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(data.icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 17,
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
                      style: const TextStyle(fontSize: 12, height: 1.25, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: _softShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: data.gradient,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: data.gradient.last.withAlpha(90),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(data.icon, color: Colors.white, size: 28),
              ),
              const Spacer(),
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: _C.textDark,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 30,
                child: Text(
                  data.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, height: 1.25, color: _C.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: _C.textMuted),
          SizedBox(height: 10),
          Text(
            'Aradığınız hizmet bulunamadı',
            style: TextStyle(fontSize: 14, color: _C.textMuted, fontWeight: FontWeight.w600),
          ),
        ],
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
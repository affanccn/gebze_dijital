import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

BoxDecoration _cardDeco([double r = 18]) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: _C.line),
    );

/// Toplanma Alanı Veri Modeli
class AssemblyArea {
  final String name;
  final String neighborhood;
  final String address;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final String features; // örn: "Su Deposu • Elektrik • Çadır Alanı"

  const AssemblyArea({
    required this.name,
    required this.neighborhood,
    required this.address,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    required this.features,
  });
}

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  // Gebze genelinde örnek acil toplanma alanları
  static const List<AssemblyArea> _allAreas = [
    AssemblyArea(
      name: 'Gebze Kent Meydanı Park Alanı',
      neighborhood: 'Hacıhalil Mahallesi',
      address: 'Hükümet Konağı Önü, İsmet Paşa Cad.',
      distanceKm: 0.6,
      latitude: 40.8028,
      longitude: 29.4307,
      features: 'Açık Alan • İletişim Noktası • İlk Yardım',
    ),
    AssemblyArea(
      name: 'Millet Bahçesi Toplanma Alanı',
      neighborhood: 'Mevlana Mahallesi',
      address: 'Mevlana Mah. Issıkgöl Cad. No:14',
      distanceKm: 1.2,
      latitude: 40.8155,
      longitude: 29.4390,
      features: 'Geniş Çadır Alanı • Su Hattı • WC',
    ),
    AssemblyArea(
      name: 'Alaettin Kurt Stadyumu & Spor Kompleksi Çevresi',
      neighborhood: 'Gaziler Mahallesi',
      address: 'Şehit Fahrettin Çevik Parkı Yanı',
      distanceKm: 1.9,
      latitude: 40.8091,
      longitude: 29.4442,
      features: 'Helikopter Pisti • Kapalı Spor Salonu',
    ),
    AssemblyArea(
      name: 'Eskihisar Sahil Parkı',
      neighborhood: 'Eskihisar Mahallesi',
      address: 'Eskihisar Sahil Yolu Cad.',
      distanceKm: 4.1,
      latitude: 40.7712,
      longitude: 29.4285,
      features: 'Açık Toplanma Alanı • Deniz Tahliye Noktası',
    ),
  ];

  String _searchAreaQuery = '';

  List<AssemblyArea> get _filteredAreas {
    final q = _searchAreaQuery.trim().toLowerCase();
    if (q.isEmpty) return _allAreas;
    return _allAreas
        .where((a) =>
            a.name.toLowerCase().contains(q) ||
            a.neighborhood.toLowerCase().contains(q) ||
            a.address.toLowerCase().contains(q))
        .toList();
  }

  void _callNumber(String title, String number) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$title ($number) aranıyor...'),
          backgroundColor: _C.navyDeep,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _openInMap(AssemblyArea area) {
    // url_launcher ile harita açmak için:
    // final uri = Uri.parse('geo:${area.latitude},${area.longitude}?q=${area.latitude},${area.longitude}(${Uri.encodeComponent(area.name)})');
    // launchUrl(uri);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${area.name} için haritada rota başlatılıyor...'),
          backgroundColor: _C.navy,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final areas = _filteredAreas;

    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(
          fontFamily: _kBodyFont,
          fontFamilyFallback: _kBodyFontFallback,
        ),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: _C.bg,
          body: Column(
            children: [
              const _Header(),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    // 112 Butonu
                    _MainCallCard(
                      title: '112 ACİL ÇAĞRI MERKEZİ',
                      subtitle: 'Ambulans, İtfaiye, Polis, Jandarma, AFAD',
                      phone: '112',
                      onTap: () => _callNumber('112 Acil', '112'),
                    ),
                    const SizedBox(height: 22),

                    // Hızlı Yardım Numaraları
                    const _SectionLabel('HIZLI ARAMA NUMARALARI'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickCallBox(
                            title: 'Gebze Belediyesi',
                            subtitle: 'Beyaz Masa Çağrı',
                            number: '444 1 890',
                            icon: Icons.account_balance_rounded,
                            color: _C.navy,
                            onTap: () => _callNumber('Gebze Belediyesi', '4441890'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickCallBox(
                            title: 'AFAD',
                            subtitle: 'Afet ve Acil Durum',
                            number: '122',
                            icon: Icons.shield_rounded,
                            color: _C.orange,
                            onTap: () => _callNumber('AFAD', '122'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // Toplanma Alanları Başlığı ve Arama Kutusu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionLabel('ACİL TOPLANMA ALANLARI'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _C.navy.withAlpha(16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${areas.length} Alan',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: _C.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Mahalle / Alan Arama Input'u
                    Container(
                      height: 46,
                      decoration: _cardDeco(14),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchAreaQuery = val),
                        style: const TextStyle(fontSize: 13, color: _C.textDark),
                        decoration: const InputDecoration(
                          hintText: 'Mahalle veya toplanma alanı ara...',
                          hintStyle: TextStyle(fontSize: 12.5, color: _C.textMuted),
                          prefixIcon: Icon(Icons.search_rounded, size: 20, color: _C.textMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Toplanma Alanı Kartları
                    if (areas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Aradığınız kritere uygun toplanma alanı bulunamadı.',
                            style: TextStyle(fontSize: 12.5, color: _C.textMuted),
                          ),
                        ),
                      )
                    else
                      for (final area in areas) ...[
                        _AssemblyAreaCard(
                          area: area,
                          onNavigate: () => _openInMap(area),
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
  const _SectionLabel(this.text);

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
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: _C.navy,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Üst Başlık ─────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _C.danger,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 17),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACİL DURUM & TOPLANMA',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Gebze acil çağrı hatları ve en yakın güvenli toplanma bölgeleri.',
                      style: TextStyle(fontSize: 11.5, color: Colors.white70),
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
                child: const Icon(Icons.emergency_rounded, color: _C.danger, size: 22),
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
  final VoidCallback onTap;

  const _MainCallCard({
    required this.title,
    required this.subtitle,
    required this.phone,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.danger, width: 1.6),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _C.danger.withAlpha(24),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_in_talk_rounded, color: _C.danger, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: _C.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 11, color: _C.textMuted, height: 1.25),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
  final VoidCallback onTap;

  const _QuickCallBox({
    required this.title,
    required this.subtitle,
    required this.number,
    required this.icon,
    required this.color,
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
          decoration: _cardDeco(18),
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
                      color: color.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 21),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _C.green.withAlpha(24),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_rounded, color: _C.green, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: _C.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: _C.textMuted),
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
  final VoidCallback onNavigate;

  const _AssemblyAreaCard({
    required this.area,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _C.green.withAlpha(24),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups_rounded, color: _C.green, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _C.textDark,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${area.neighborhood} • ${area.address}',
                      style: const TextStyle(fontSize: 11.5, color: _C.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Mesafe rozeti
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.navy.withAlpha(16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.near_me_rounded, size: 12, color: _C.navy),
                    const SizedBox(width: 3),
                    Text(
                      '${area.distanceKm} km',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _C.navy,
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
                    const Icon(Icons.info_outline_rounded, size: 14, color: _C.orange),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        area.features,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _C.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Haritada Yol Tarifi Butonu
              ElevatedButton.icon(
                onPressed: onNavigate,
                icon: const Icon(Icons.directions_rounded, size: 15),
                label: const Text('Yol Tarifi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.navy.withAlpha(16),
                  foregroundColor: _C.navy,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
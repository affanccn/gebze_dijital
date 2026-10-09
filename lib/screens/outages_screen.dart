import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        color: const Color(0xFF0A2A66).withAlpha(20),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ];

class OutagesScreen extends StatefulWidget {
  const OutagesScreen({super.key});

  @override
  State<OutagesScreen> createState() => _OutagesScreenState();
}

class _OutagesScreenState extends State<OutagesScreen> {
  // 0: Tümü, 1: Su (İSU), 2: Elektrik (SEDAŞ), 3: Doğalgaz (PALGAZ)
  int _selectedFilter = 0;

  // Veritabanında kayıt yoksa gösterilecek yedek demo veriler
  static const _fallbackOutages = [
    {
      'type': 'su',
      'title': 'Ana İsale Hattı Bakım Çalışması',
      'neighborhood': 'Osman Yılmaz & Köşklü Çeşme Mah.',
      'startDate': '09.10.2026 10:00',
      'endDate': '09.10.2026 18:00',
      'status': 'Devam Ediyor',
      'provider': 'İSU',
    },
    {
      'type': 'elektrik',
      'title': 'Trafo Yenileme ve Şebeke İyileştirme',
      'neighborhood': 'Arapçeşme Mahallesi (Kısmi)',
      'startDate': '10.10.2026 09:00',
      'endDate': '10.10.2026 14:00',
      'status': 'Planlı Kesinti',
      'provider': 'SEDAŞ',
    },
    {
      'type': 'gaz',
      'title': 'Altyapı Bağlantı ve Vana Değişimi',
      'neighborhood': 'Mustafapaşa Mahallesi 712. Sokak',
      'startDate': '11.10.2026 13:00',
      'endDate': '11.10.2026 17:00',
      'status': 'Planlı Kesinti',
      'provider': 'PALGAZ',
    },
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
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: _C.bg,
          body: Column(
            children: [
              _Header(),
              _buildFilterChips(),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('outages').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Veri yüklenemedi: ${snapshot.error}'));
                    }

                    List<Map<String, dynamic>> items = [];

                    // Firestore'da veri varsa onu alır, yoksa fallback demo verilerini kullanır
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      items = snapshot.data!.docs.map((d) => d.data()).toList();
                    } else if (snapshot.connectionState == ConnectionState.active ||
                        snapshot.connectionState == ConnectionState.done) {
                      items = _fallbackOutages;
                    } else {
                      items = _fallbackOutages; // bekleme anında da boş görünmesin
                    }

                    // Kategori filtrelemesi
                    final filtered = items.where((item) {
                      final type = (item['type'] ?? '').toString().toLowerCase();
                      if (_selectedFilter == 1) return type == 'su';
                      if (_selectedFilter == 2) return type == 'elektrik';
                      if (_selectedFilter == 3) return type == 'gaz' || type == 'dogalgaz';
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'Bu kategoride planlı bir kesinti bulunmuyor.',
                          style: TextStyle(color: _C.textMuted, fontWeight: FontWeight.w600),
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => _OutageCard(data: filtered[i]),
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

  Widget _buildFilterChips() {
    final filters = ['Tümü', 'Su (İSU)', 'Elektrik (SEDAŞ)', 'Doğalgaz'];
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 14, bottom: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = _selectedFilter == i;
          return ChoiceChip(
            label: Text(filters[i]),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedFilter = i),
            selectedColor: _C.navy,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : _C.textDark,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? _C.navy : Colors.grey.withAlpha(50),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ───────────────────────── Üst Başlık ─────────────────────────

class _Header extends StatelessWidget {
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
          padding: const EdgeInsets.fromLTRB(16, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'PLANLI KESİNTİLER',
                      style: TextStyle(
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
                    child: const Icon(Icons.power_off_rounded, color: Colors.white, size: 24),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 48, top: 4),
                child: Text(
                  'Gebze geneli su, elektrik ve doğalgaz kesinti takibi',
                  style: TextStyle(fontSize: 12.5, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Kesinti Kartı ─────────────────────────

class _OutageCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OutageCard({required this.data});

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

  @override
  Widget build(BuildContext context) {
    final type = (data['type'] ?? '').toString();
    final color = _getTypeColor(type);
    final icon = _getTypeIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _softShadow(),
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
                  color: color.withAlpha(30),
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
                      data['title'] ?? 'Planlı Çalışma',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: _C.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sağlayıcı: ${data['provider'] ?? 'İlgili Kurum'}',
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['status'] ?? 'Planlı',
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
          Divider(height: 1, color: Colors.grey.withAlpha(35)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: _C.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data['neighborhood'] ?? 'Tüm Mahalleler',
                  style: const TextStyle(fontSize: 12.5, color: _C.textDark, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 16, color: _C.textMuted),
              const SizedBox(width: 6),
              Text(
                '${data['startDate'] ?? '-'}  ➔  ${data['endDate'] ?? '-'}',
                style: const TextStyle(fontSize: 11.5, color: _C.textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/localization/app_strings.dart';

class CenterAmbulanceTab extends ConsumerStatefulWidget {
  const CenterAmbulanceTab({super.key});

  @override
  ConsumerState<CenterAmbulanceTab> createState() => _CenterAmbulanceTabState();
}

class _CenterAmbulanceTabState extends ConsumerState<CenterAmbulanceTab> {
  static const String _centerPhone = '(0262) 642 04 30';
  static const String _centerPhoneClean = '02626420430';
  static const String _centerAddress = 'Pelitli, Yeni Mezarlık Yolu no:49, 41400 Gebze/Kocaeli';
  static const double _centerLat = 40.8715;
  static const double _centerLng = 29.4988;
  static const String _centerWebsite = 'http://www.gebze.bel.tr/';

  final PageController _pageController = PageController();
  int _activeImageIndex = 0;

  final List<Map<String, String>> _photos = [
    {
      'path': 'gorsel/pati/merkez_1.jpg',
      'title': 'Rehabilitasyon Merkezi Ana Giriş & İdari Bina',
    },
    {
      'path': 'gorsel/pati/ambulans.jpg',
      'title': 'Gebze Belediyesi Hayvan Ambulansı Acil Müdahale Aracı',
    },
    {
      'path': 'gorsel/pati/merkez_2.jpg',
      'title': 'Klinik, Ameliyathane & Yoğun Bakım Ünitesi',
    },
    {
      'path': 'gorsel/pati/merkez_3.jpg',
      'title': 'Doğal Yaşam & Rehabilitasyon Barınma Alanları',
    },
    {
      'path': 'gorsel/pati/merkez_4.jpg',
      'title': 'Sahiplendirme ve Eğitim Bahçesi',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMaps(double lat, double lng, String label) async {
    final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng($label)');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openWeb(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // 1. ACİL HAYVAN AMBULANSI ÇAĞRI BANNERI (KIRMIZI/TURUNCU VURGU)
        _buildEmergencyBanner(context, lang),
        const SizedBox(height: 18),

        // 2. HAYVAN AMBULANSI NEDİR & NE İŞE YARAR?
        _buildAmbulanceInfoCard(context, lang),
        const SizedBox(height: 18),

        // 3. HANGİ DURUMLARDA ÇAĞRILIR & MÜDAHALELER
        _buildInterventionsCard(context, lang),
        const SizedBox(height: 24),

        // 4. BÖLÜM AYIRICI BAŞLIK: REHABİLİTASYON VE EĞİTİM MERKEZİ
        _buildSectionHeader(
          title: AppStrings.get('rehab_center_section_title', lang),
          subtitle: AppStrings.get('rehab_center_section_sub', lang),
          icon: Icons.local_hospital_rounded,
        ),
        const SizedBox(height: 14),

        // 5. MERKEZ HAKKINDA GÖRSELLER & BİLGİ KARTI
        _buildCenterCard(context, lang),
        const SizedBox(height: 18),

        // 6. ÇALIŞMA SAATLERİ & ULAŞIM
        _buildWorkingHoursCard(context, lang),
      ],
    );
  }

  Widget _buildEmergencyBanner(BuildContext context, String lang) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE5231B), Color(0xFFFF5A4F)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5231B).withAlpha(80),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('ambulance_banner_title', lang),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      AppStrings.get('ambulance_banner_team', lang),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.get('ambulance_banner_desc', lang),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _makeCall(_centerPhoneClean),
                  icon: const Icon(Icons.call_rounded, size: 20),
                  label: Text(
                    AppStrings.get('call_ambulance_btn', lang),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFE5231B),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmbulanceInfoCard(BuildContext context, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2A66).withAlpha(18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00).withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emergency_share_rounded, color: Color(0xFFFF7A00), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.get('ambulance_what_is', lang),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A1F44),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.get('ambulance_what_is_desc_full', lang),
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF334A6E),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionsCard(BuildContext context, String lang) {
    final conditions = [
      {
        'icon': Icons.car_crash_rounded,
        'title': AppStrings.get('cond_accident', lang),
        'desc': AppStrings.get('cond_accident_sub', lang),
      },
      {
        'icon': Icons.warning_amber_rounded,
        'title': AppStrings.get('cond_trauma', lang),
        'desc': AppStrings.get('cond_trauma_sub', lang),
      },
      {
        'icon': Icons.coronavirus_rounded,
        'title': AppStrings.get('cond_poison', lang),
        'desc': AppStrings.get('cond_poison_sub', lang),
      },
      {
        'icon': Icons.healing_rounded,
        'title': AppStrings.get('cond_wound', lang),
        'desc': AppStrings.get('cond_wound_sub', lang),
      },
    ];

    final procedures = [
      AppStrings.get('proc_1', lang),
      AppStrings.get('proc_2', lang),
      AppStrings.get('proc_3', lang),
      AppStrings.get('proc_4', lang),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2A66).withAlpha(18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2E7D32), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.get('conditions_title', lang),
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A1F44),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: conditions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, i) {
              final item = conditions[i];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FD),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0A2A66).withAlpha(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(item['icon'] as IconData, size: 20, color: const Color(0xFFE5231B)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0A1F44)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['desc'] as String,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF5F6F8A), height: 1.25),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Text(
            AppStrings.get('ambulance_interventions_label', lang),
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A1F44),
            ),
          ),
          const SizedBox(height: 8),
          ...procedures.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.shield_outlined, size: 14, color: Color(0xFF1E5BC6)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF4A5568), height: 1.35),
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

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A2A66).withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF0A2A66), size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0A1F44),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF5F6F8A)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCenterCard(BuildContext context, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2A66).withAlpha(18),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Görsel Carousel Alanı (5 adet görsel destekli slider)
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _photos.length,
                  onPageChanged: (i) => setState(() => _activeImageIndex = i),
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return Image.asset(
                      photo['path']!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'gorsel/gebze_gorsel.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, err2, st2) {
                            return Container(
                              color: const Color(0xFF0A2A66),
                              child: const Center(
                                child: Icon(Icons.pets_rounded, size: 64, color: Colors.white54),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                Positioned(
                  bottom: 10,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(170),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _photos[_activeImageIndex]['title']!,
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${_activeImageIndex + 1}/${_photos.length}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 20),
                    const SizedBox(width: 4),
                    const Text(
                      '4.2',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0A1F44)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.get('google_reviews_count', lang),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5F6F8A)),
                    ),
                    const Spacer(),
                    Text(
                      AppStrings.get('pelitli_hospital', lang),
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E5BC6), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.get('center_role_title', lang),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A1F44),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.get('center_role_desc', lang),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334A6E),
                    height: 1.48,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Konum & İletişim Bilgileri
                _buildInfoRow(
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFFE5231B),
                  title: AppStrings.get('center_open_address', lang),
                  value: _centerAddress,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  icon: Icons.phone_rounded,
                  iconColor: const Color(0xFF0A2A66),
                  title: AppStrings.get('center_phone_label', lang),
                  value: _centerPhone,
                ),
                const SizedBox(height: 16),

                // Aksiyon Butonları (Yol Tarifi, Telefon Et, Web Sitesi)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _makeCall(_centerPhoneClean),
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: Text(AppStrings.get('btn_call', lang)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0A2A66),
                          side: BorderSide(color: const Color(0xFF0A2A66).withAlpha(60)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openMaps(_centerLat, _centerLng, 'Gebze Belediyesi Sokak Hayvanları Merkezi'),
                        icon: const Icon(Icons.directions_rounded, size: 18),
                        label: Text(AppStrings.get('btn_directions', lang)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A2A66),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _openWeb(_centerWebsite),
                    icon: const Icon(Icons.language_rounded, size: 17),
                    label: Text(AppStrings.get('btn_visit_website', lang)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1E5BC6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHoursCard(BuildContext context, String lang) {
    final days = [
      {'day': AppStrings.get('day_mon', lang), 'hours': '09:00 – 16:00', 'open': true},
      {'day': AppStrings.get('day_tue', lang), 'hours': '09:00 – 16:00', 'open': true},
      {'day': AppStrings.get('day_wed', lang), 'hours': '09:00 – 16:00', 'open': true},
      {'day': AppStrings.get('day_thu', lang), 'hours': '09:00 – 16:00', 'open': true},
      {'day': AppStrings.get('day_fri', lang), 'hours': '09:00 – 16:00', 'open': true},
      {'day': AppStrings.get('day_sat', lang), 'hours': AppStrings.get('closed_emergency_except', lang), 'open': false},
      {'day': AppStrings.get('day_sun', lang), 'hours': AppStrings.get('closed_emergency_except', lang), 'open': false},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2A66).withAlpha(16),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: Color(0xFF0A2A66), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.get('visiting_hours_title', lang),
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A1F44),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...days.map(
            (d) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    d['day'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: d['open'] as bool ? FontWeight.w600 : FontWeight.normal,
                      color: const Color(0xFF0A1F44),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: d['open'] as bool
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      d['hours'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: d['open'] as bool
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFC62828),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.get('ambulance_shift_note', lang),
            style: const TextStyle(fontSize: 11, color: Color(0xFF5F6F8A), fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF5F6F8A), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0A1F44), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

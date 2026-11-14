import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/phone_launcher.dart';

class AdoptionTab extends ConsumerWidget {
  const AdoptionTab({super.key});

  static const String _centerPhoneClean = '02626420430';
  static const String _centerAddress =
      'Pelitli, Yeni Mezarlık Yolu no:49, 41400 Gebze/Kocaeli';
  static const double _centerLat = 40.8715;
  static const double _centerLng = 29.4988;
  static const String _eBelediyeBasvuruUrl =
      'https://ulakbel.gebze.bel.tr/WebBasvuru/';
  static const String _gebzePortalUrl = 'https://portal.gebze.bel.tr/';

  Future<void> _callCenter(BuildContext context, String lang) async {
    await PhoneLauncher.makeCall(context, _centerPhoneClean, lang: lang);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse(
      'https://maps.google.com/?q=$_centerLat,$_centerLng(Gebze Belediyesi Sokak Hayvanları Rehabilitasyon Merkezi)',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        _buildHeroCard(context, isDark),
        const SizedBox(height: 16),

        _buildApplicationActionsCard(context, isDark),
        const SizedBox(height: 18),

        _buildProcessCard(context, lang, isDark),
        const SizedBox(height: 18),

        _buildLegalNoticeCard(isDark),
        const SizedBox(height: 18),

        _buildCenterContactCard(context, lang, isDark),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E5BC6), Color(0xFF0A2A66)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2A66).withAlpha(40),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
                  color: Colors.white.withAlpha(35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Can Dostlarımızı Sahiplenme',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Gebze Belediyesi Veteriner Hizmetleri',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Rehabilitasyon merkezimizde bakım ve tedavileri tamamlanan can dostlarımıza sıcak bir yuva kazandırmak için başvurular Gebze Belediyesi E-Belediye sistemi üzerinden resmi olarak alınmaktadır.',
            style: TextStyle(color: Colors.white, fontSize: 13.5, height: 1.45),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBadge(
                icon: Icons.check_circle_outline_rounded,
                text: 'Tamamen Ücretsiz',
              ),
              _buildBadge(
                icon: Icons.verified_rounded,
                text: 'Aşılı & Çipli Teslimat',
              ),
              _buildBadge(
                icon: Icons.volunteer_activism_rounded,
                text: 'Satın Alma, Sahiplen!',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationActionsCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF0A2A66).withAlpha(15),
                  blurRadius: 16,
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
                  color: const Color(0xFF1E5BC6).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.laptop_chromebook_rounded,
                  color: Color(0xFF1E5BC6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'E-Belediye Başvuru Kanalları',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0A1F44),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Sahiplendirme talebinizi Gebze Belediyesi Web Başvuru portalından hemen iletebilir veya durumunu sorgulayabilirsiniz.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5F6F8A),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openUrl(_eBelediyeBasvuruUrl),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text(
                'E-Belediye Web Başvuru Sayfası',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E5BC6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openUrl(_gebzePortalUrl),
              icon: const Icon(Icons.public_rounded, size: 18),
              label: const Text(
                'Gebze Belediyesi Vatandaş Portalı',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF0A2A66),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF1E5BC6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessCard(BuildContext context, String lang, bool isDark) {
    final steps = [
      {
        'step': '1',
        'title': 'E-Belediye veya Merkezden Başvuru',
        'desc': 'Gebze Belediyesi E-Belediye portalı üzerinden başvurunuzu yapabilir veya merkezimizi telefonla arayarak randevu oluşturabilirsiniz.',
      },
      {
        'step': '2',
        'title': 'Rehabilitasyon Merkezini Ziyaret',
        'desc': 'Pelitli Sokak Hayvanları Bakım ve Rehabilitasyon Merkezimize gelerek uzman veteriner hekimlerimiz eşliğinde can dostlarımızla tanışın.',
      },
      {
        'step': '3',
        'title': 'Kimlik & Sahiplendirme Taahhütnamesi',
        'desc': '18 yaşını doldurmuş vatandaşlarımız T.C. kimlik belgesiyle ücretsiz sahiplendirme taahhütnamesini ve formunu imzalar.',
      },
      {
        'step': '4',
        'title': 'Mikroçip, Aşı Karnesi & Teslimat',
        'desc': 'Kuduz ve karma aşıları tamamlanmış, mikroçipi PETVET sistemine adınıza kaydedilmiş olarak yeni dostunuz size teslim edilir.',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF0A2A66).withAlpha(15),
                  blurRadius: 16,
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
                  color: const Color(0xFF2E7D32).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.format_list_numbered_rounded,
                  color: Color(0xFF2E7D32),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sahiplendirme Süreci Nasıl İşler?',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0A1F44),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E5BC6), Color(0xFF0A2A66)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      s['step']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['title']!,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0A1F44),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          s['desc']!,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF5F6F8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegalNoticeCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF1E5BC6),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Yasal Şartlar ve Bilgilendirme',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0A1F44),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildNoticeItem(
            '18 Yaş Şartı',
            '5199 sayılı Hayvanları Koruma Kanunu gereğince 18 yaşından gün almamış vatandaşlarımız adına sahiplendirme işlemi yapılamaz.',
            isDark,
          ),
          const SizedBox(height: 8),
          _buildNoticeItem(
            'Mikroçip & PETVET Kaydı',
            'Tüm can dostlarımız Tarım ve Orman Bakanlığı evcil hayvan kayıt sistemine (PETVET) sahiplenen kişi adına resmi olarak tescil edilir.',
            isDark,
          ),
          const SizedBox(height: 8),
          _buildNoticeItem(
            'Ücretsiz Hizmet',
            'Gebze Belediyesi bünyesindeki tüm sahiplendirme, kuduz aşısı, iç-dış parazit ve çip uygulamaları tamamen ücretsizdir.',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(String title, String desc, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Icon(
            Icons.fiber_manual_record,
            size: 8,
            color: Color(0xFF1E5BC6),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF475569),
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterContactCard(
    BuildContext context,
    String lang,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
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
                  color: const Color(0xFFFF7A00).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFFF7A00),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rehabilitasyon Merkezi İletişim',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0A1F44),
                      ),
                    ),
                    Text(
                      'Ziyaret Saatleri: Hafta içi 10:00 - 16:00',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF5F6F8A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _centerAddress,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _callCenter(context, lang),
                  icon: const Icon(Icons.call_rounded, size: 17),
                  label: const Text(
                    'Merkezi Ara',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E5BC6),
                    side: const BorderSide(color: Color(0xFF1E5BC6)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openMaps,
                  icon: const Icon(Icons.navigation_rounded, size: 17),
                  label: const Text(
                    'Yol Tarifi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A2A66),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

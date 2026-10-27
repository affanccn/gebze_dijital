import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/localization/app_strings.dart';

/// Gebze Belediyesi - Talep / Şikayet / Öneri (Bildir)
/// Dosya yolu: lib/screens/report_screen.dart
///
/// Başvurular artık uygulama içinde alınmaz; kullanıcı belediyenin
/// ULAKBEL (Çözüm Masası) sayfasına yönlendirilir.
const String kUlakbelUrl =
    'https://ebelediye.gebze.bel.tr/NicoPortal/faces/portal/beyazMasa/CozumMasasi.xhtml#';

class _C {
  static const navy = Color(0xFF0A2A66);
  static const navyDeep = Color(0xFF061B45);
  static const orange = Color(0xFFFF7A00);
  static const bg = Color(0xFFF1F5FD);
  static const textDark = Color(0xFF0A1F44);
  static const textMuted = Color(0xFF5F6F8A);
  static const border = Color(0xFFE4E9F2);
}

String _t(String lang, String tr, String en, String ar) =>
    lang == 'en' ? en : (lang == 'ar' ? ar : tr);

class ReportScreen extends ConsumerWidget {
  /// Eski çağrılarla uyumluluk için duruyor (ana sayfa, alt menü); artık
  /// kullanılmıyor, ULAKBEL herkese açık.
  final bool isGuest;
  final ValueChanged<int>? onNavTap;
  const ReportScreen({super.key, this.isGuest = false, this.onNavTap});

  Future<void> _openUlakbel(BuildContext context, String lang) async {
    final messenger = ScaffoldMessenger.of(context);
    bool ok = false;
    try {
      ok = await launchUrl(
        Uri.parse(kUlakbelUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: _C.navyDeep,
            content: Text(
              _t(
                lang,
                'Sayfa açılamadı. Lütfen tekrar deneyin.',
                'Could not open the page. Please try again.',
                'تعذّر فتح الصفحة. يرجى المحاولة مرة أخرى.',
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : _C.textDark;
    final muted = isDark ? const Color(0xFF94A3B8) : _C.textMuted;

    Widget chip(IconData icon, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : _C.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : _C.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? const Color(0xFF60A5FA) : _C.navy,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : _C.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_C.navy, _C.navyDeep],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Color(0x330A2A66),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (onNavTap != null) {
                        onNavTap!(0);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _t(lang, 'Talep & Şikayet', 'Requests & Complaints',
                              'الطلبات والشكاوى'),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          _t(
                            lang,
                            'İstek, şikayet ve önerilerinizi belediyeye iletin',
                            'Send your requests, complaints and suggestions',
                            'أرسل طلباتك وشكاواك واقتراحاتك إلى البلدية',
                          ),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : _C.border,
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: _C.navy.withAlpha(22),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFA11F), Color(0xFFFF6A00)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _t(
                      lang,
                      'Talep, Şikayet ve Önerileriniz İçin',
                      'For Your Requests, Complaints and Suggestions',
                      'لطلباتك وشكاواك واقتراحاتك',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                      color: text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _t(
                      lang,
                      'Başvurularınız Gebze Belediyesi ULAKBEL sayfasından alınır. Aşağıdaki butonla sayfayı açıp formu doldurabilirsiniz.',
                      'Applications are received through the Gebze Municipality ULAKBEL page. Tap the button below to open it and fill in the form.',
                      'تُستلم الطلبات عبر صفحة ULAKBEL التابعة لبلدية جبزة. اضغط على الزر أدناه لفتح الصفحة وتعبئة النموذج.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, height: 1.45, color: muted),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      chip(Icons.handshake_outlined,
                          _t(lang, 'Talep', 'Request', 'طلب')),
                      chip(Icons.report_problem_outlined,
                          _t(lang, 'Şikayet', 'Complaint', 'شكوى')),
                      chip(Icons.lightbulb_outline_rounded,
                          _t(lang, 'Öneri', 'Suggestion', 'اقتراح')),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _openUlakbel(context, lang),
                      icon: const Icon(Icons.open_in_new_rounded, size: 20),
                      label: Text(
                        _t(lang, "ULAKBEL'e Git", 'Go to ULAKBEL',
                            'الانتقال إلى ULAKBEL'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: 2,
        lang: lang,
        onTap: (i) {
          if (onNavTap != null) {
            onNavTap!(i);
          } else if (i != 2) {
            Navigator.of(context).pop();
          }
        },
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
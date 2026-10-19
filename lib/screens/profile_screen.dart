import 'auth_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/profile/models/user_profile.dart';
import '../features/profile/models/gebze_avatar.dart';
import '../features/profile/services/profile_service.dart';
import '../features/profile/widgets/gebze_avatar_picker_dialog.dart';
import '../core/localization/app_strings.dart';
import '../core/accessibility/font_scale_provider.dart';
import '../core/theme/theme_provider.dart';
import 'my_requests_screen.dart';
import 'report_common.dart';
import 'services_screen.dart';

class _C {
  static const navy = Color(0xFF0A2A66);
  static const navyDeep = Color(0xFF061B45);
  static const orange = Color(0xFFFF7A00);
  static const bg = Color(0xFFF1F5FD);
  static const textDark = Color(0xFF0A1F44);
  static const textMuted = Color(0xFF5F6F8A);
  static const danger = Color(0xFFE5231B);
  static const green = Color(0xFF2E7D32);

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
    color: const Color(0xFF0A2A66).withAlpha(18),
    blurRadius: 16,
    offset: const Offset(0, 5),
  ),
];

const List<String> _kGebzeNeighborhoods = [
  'Mustafapaşa',
  'Osman Yılmaz',
  'Arapçeşme',
  'Hacıhalil',
  'Mevlana',
  'Gaziler',
  'Eskihisar',
  'Köşklü Çeşme',
  'Güzeller',
  'Yenikent',
  'İnönü',
  'İstasyon',
  'Tatlıkuyu',
  'Barış',
  'Kirazpınar',
  'Sultan Orhan',
  'Ulus',
  'Yavuz Selim',
  'Cumhuriyet',
  'Beylikbağı',
  'Hürriyet',
  'Mimar Sinan',
];

class ProfileScreen extends ConsumerStatefulWidget {
  final ValueChanged<int>? onNavTap;

  /// true ise ekran açılır açılmaz Aktiviteler > Talepler sheet'i açılır
  /// (Çek & Gönder sonrası "Taleplerim" için).
  final bool openRequestsOnStart;

  const ProfileScreen({
    super.key,
    this.onNavTap,
    this.openRequestsOnStart = false,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.openRequestsOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openActivitiesSheet(context, 'talep', ref.read(appLanguageProvider));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
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
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: context.isDark ? const Color(0xFF0F172A) : _C.bg,
          body: profileAsync.when(
            data: (profile) => _buildProfileContent(context, profile),
            loading: () =>
                const Center(child: CircularProgressIndicator(color: _C.navy)),
            error: (err, _) => _buildErrorState(context, err.toString()),
          ),
          bottomNavigationBar: _BottomNav(
            index: 4,
            onTap: (i) {
              if (widget.onNavTap != null) {
                widget.onNavTap!(i);
              } else if (i != 4) {
                Navigator.of(context).pop();
                if (i == 3) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ServicesScreen()),
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserProfile profile) {
    final lang = ref.watch(appLanguageProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildHeroHeader(context, profile, lang),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsCard(context, profile, lang),
                const SizedBox(height: 22),
                _buildSectionTitle(
                  AppStrings.get('section_account', lang),
                  Icons.person_rounded,
                ),
                const SizedBox(height: 10),
                _buildAccountSection(context, profile, lang),
                const SizedBox(height: 22),
                _buildSectionTitle(
                  AppStrings.get('section_activities', lang),
                  Icons.history_rounded,
                ),
                const SizedBox(height: 10),
                _buildActivitiesSection(context, profile, lang),
                const SizedBox(height: 22),
                _buildSectionTitle(
                  AppStrings.get('section_settings', lang),
                  Icons.tune_rounded,
                ),
                const SizedBox(height: 10),
                _buildSettingsSection(context, profile, lang),
                const SizedBox(height: 22),
                _buildSectionTitle(
                  AppStrings.get('section_support', lang),
                  Icons.headset_mic_rounded,
                ),
                const SizedBox(height: 10),
                _buildSupportSection(context, lang),
                const SizedBox(height: 28),
                _buildActionButtons(context, profile, lang),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    AppStrings.get('app_footer', lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _C.textMuted.withAlpha(160),
                      fontWeight: FontWeight.w500,
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

  // ───────────────────────── Üst Header (Hero) ─────────────────────────

  Widget _buildHeroHeader(
    BuildContext context,
    UserProfile profile,
    String lang,
  ) {
    const heroH = 260.0;

    return Container(
      width: double.infinity,
      height: heroH,
      decoration: const BoxDecoration(
        color: _C.navyDeep,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x330A2A66),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan: Gebze Görseli
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
            child: Image.asset(
              'gorsel/gebze_gorsel.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: _C.navyGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          // Karartma ve Lacivert Degrade Katmanı
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _C.navyDeep.withAlpha(160),
                  _C.navyDeep.withAlpha(235),
                  _C.navyDeep,
                ],
                stops: const [0.0, 0.65, 1.0],
              ),
            ),
          ),
          // İçerik: Geri Butonu + Kullanıcı Karşılama ve Profil Resmi
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      Text(
                        AppStrings.get('profile_screen_title', lang),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _openEditProfileDialog(context, profile, lang),
                        icon: const Icon(
                          Icons.edit_note_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(80),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: const Color(0xFF1E5BC6),
                              backgroundImage:
                                  getAvatarImageProvider(profile.avatarUrl),
                              child: getAvatarImageProvider(profile.avatarUrl) == null
                                  ? Text(
                                      _getInitials(profile.fullName),
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () =>
                                  _openAvatarPicker(context, profile, lang),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: _C.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // İsim ve Mahalle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.get('hello', lang),
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(35),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        size: 12,
                                        color: _C.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${profile.neighborhood} ${AppStrings.get('mahalle_abbr', lang)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (profile.isVerified)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32)
                                          .withAlpha(190),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.verified_rounded,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          AppStrings.get(
                                            'verified_badge',
                                            lang,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Sayaç Kartı ─────────────────────────

  Widget _buildStatsCard(
    BuildContext context,
    UserProfile profile,
    String lang,
  ) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
        boxShadow: isDark ? [] : _softShadow(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            AppStrings.get('stat_requests', lang),
            '${ref.watch(myReportCountProvider)}',
            Icons.assignment_rounded,
            () => _openActivitiesSheet(context, 'talep', lang),
          ),
          _buildStatDivider(),
          _buildStatItem(
            AppStrings.get('stat_suggestions', lang),
            '${profile.totalSuggestions}',
            Icons.record_voice_over_rounded,
            () => _openActivitiesSheet(context, 'oneri', lang),
          ),
          _buildStatDivider(),
          _buildStatItem(
            AppStrings.get('stat_supports', lang),
            '${profile.totalSupported}',
            Icons.thumb_up_rounded,
            () => _openActivitiesSheet(context, 'destek', lang),
          ),
          _buildStatDivider(),
          _buildStatItem(
            AppStrings.get('stat_saved', lang),
            '${profile.totalSaved}',
            Icons.bookmark_rounded,
            () => _openActivitiesSheet(context, 'kayit', lang),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isDark = context.isDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? const Color(0xFF60A5FA) : _C.navy,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : _C.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    final isDark = context.isDark;
    return Container(
      width: 1,
      height: 34,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }

  // ───────────────────────── Bölüm Başlığı ─────────────────────────

  Widget _buildSectionTitle(String title, IconData icon) {
    final isDark = context.isDark;
    return Row(
      children: [
        Icon(icon, size: 17, color: isDark ? const Color(0xFF60A5FA) : _C.navy),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Hesap Bölümü ─────────────────────────

  Widget _buildAccountSection(
    BuildContext context,
    UserProfile profile,
    String lang,
  ) {
    return _buildGroupCard([
      _buildListTile(
        icon: Icons.badge_rounded,
        iconColor: _C.navy,
        title: AppStrings.get('tile_my_info', lang),
        subtitle: '${profile.fullName} • ${profile.phoneNumber}',
        onTap: () => _openEditProfileDialog(context, profile, lang),
      ),
      _buildDivider(),
      _buildListTile(
        icon: Icons.home_work_rounded,
        iconColor: _C.orange,
        title: AppStrings.get('tile_neighborhood', lang),
        subtitle:
            '${profile.neighborhood} ${AppStrings.get('mahalle_suffix', lang)}',
        onTap: () => _openNeighborhoodPicker(context, profile, lang),
      ),
      _buildDivider(),
      _buildListTile(
        icon: Icons.notifications_active_rounded,
        iconColor: const Color(0xFF0288D1),
        title: AppStrings.get('tile_notifications', lang),
        subtitle: AppStrings.get('tile_notifications_sub', lang),
        onTap: () => _openNotificationPreferences(context, profile, lang),
      ),
    ]);
  }

  // ───────────────────────── Aktiviteler Bölümü ─────────────────────────

  Widget _buildActivitiesSection(
    BuildContext context,
    UserProfile profile,
    String lang,
  ) {
    return _buildGroupCard([
      _buildListTile(
        icon: Icons.assignment_turned_in_rounded,
        iconColor: const Color(0xFF1E5BC6),
        title: AppStrings.get('act_requests_title', lang),
        subtitle:
            '${ref.watch(myReportCountProvider)} ${AppStrings.get('stat_requests', lang)}',
        onTap: () => _openActivitiesSheet(context, 'talep', lang),
      ),
      _buildDivider(),
      _buildListTile(
        icon: Icons.lightbulb_rounded,
        iconColor: const Color(0xFFF57C00),
        title: AppStrings.get('act_suggestions_title', lang),
        subtitle:
            '${profile.totalSuggestions} ${AppStrings.get('stat_suggestions', lang)}',
        onTap: () => _openActivitiesSheet(context, 'oneri', lang),
      ),
      _buildDivider(),
      _buildListTile(
        icon: Icons.favorite_rounded,
        iconColor: const Color(0xFFE5231B),
        title: AppStrings.get('act_supports_title', lang),
        subtitle:
            '${profile.totalSupported} ${AppStrings.get('stat_supports', lang)}',
        onTap: () => _openActivitiesSheet(context, 'destek', lang),
      ),
      _buildDivider(),
      _buildListTile(
        icon: Icons.bookmark_rounded,
        iconColor: _C.navy,
        title: AppStrings.get('act_saved_title', lang),
        subtitle: '${profile.totalSaved} ${AppStrings.get('stat_saved', lang)}',
        onTap: () => _openActivitiesSheet(context, 'kayit', lang),
      ),
    ]);
  }

  // ───────────────────────── Ayarlar Bölümü ─────────────────────────

  Widget _buildSettingsSection(
    BuildContext context,
    UserProfile profile,
    String lang,
  ) {
    final activeLang = ref.watch(appLanguageProvider);
    final activeTheme = ref.watch(appThemeModeProvider);

    String langLabel;
    switch (activeLang) {
      case 'en':
        langLabel = 'English (EN)';
        break;
      case 'ar':
        langLabel = 'العربية (AR)';
        break;
      default:
        langLabel = 'Türkçe (TR)';
    }

    String themeLabel;
    switch (activeTheme) {
      case ThemeMode.dark:
        themeLabel = AppStrings.get('theme_dark', activeLang);
        break;
      case ThemeMode.system:
        themeLabel = AppStrings.get('theme_system', activeLang);
        break;
      default:
        themeLabel = AppStrings.get('theme_light', activeLang);
    }

    return _buildGroupCard([
      _buildListTile(
        icon: Icons.language_rounded,
        iconColor: const Color(0xFF00897B),
        title: AppStrings.get('tile_language', lang),
        subtitle: langLabel,
        onTap: () => _openLanguagePicker(context, profile, lang),
      ),
      _buildDivider(),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF5E35B1).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.format_size_rounded,
                color: Color(0xFF5E35B1),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get('tile_large_font', lang),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: context.isDark ? Colors.white : _C.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.get('tile_large_font_sub', lang),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.isDark
                          ? const Color(0xFF94A3B8)
                          : _C.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: ref.watch(appLargeFontProvider),
              activeThumbColor: _C.navy,
              activeTrackColor: const Color(0xFF90CAF9),
              onChanged: (val) {
                ref.read(appLargeFontProvider.notifier).setLargeFont(val);
                ref.read(profileServiceProvider).updateLargeFont(val);
              },
            ),
          ],
        ),
      ),
      _buildDivider(),
      _buildListTile(
        icon: Icons.palette_rounded,
        iconColor: const Color(0xFF6D4C41),
        title: AppStrings.get('tile_theme', lang),
        subtitle: themeLabel,
        onTap: () => _openThemePicker(context, profile, lang),
      ),
    ]);
  }

  // ───────────────────────── Destek & İletişim ─────────────────────────

  Widget _buildSupportSection(BuildContext context, String lang) {
    return _buildGroupCard([
      _buildListTile(
        icon: Icons.phone_in_talk_rounded,
        iconColor: const Color(0xFF2E7D32),
        title: AppStrings.get('tile_gim', lang),
        subtitle: AppStrings.get('tile_gim_sub', lang),
        onTap: () => _callMunicipalCallCenter(lang),
      ),
      _buildDivider(),
      _buildListTile(
        icon: Icons.privacy_tip_rounded,
        iconColor: const Color(0xFF0288D1),
        title: AppStrings.get('tile_privacy', lang),
        subtitle: AppStrings.get('tile_privacy_sub', lang),
        onTap: () => _openPrivacySheet(context),
      ),
    ]);
  }

  // ───────────────────────── Butonlar (Çıkış & Hesap Sil) ─────────────────────────

  Widget _buildActionButtons(
    BuildContext context,
    UserProfile profile,
    String lang,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Çıkış Yap Butonu
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _confirmSignOut(context, lang),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: Text(
              AppStrings.get('btn_logout', lang),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              foregroundColor: isDark ? Colors.white : _C.navy,
              elevation: 0,
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Hesabı Sil Butonu
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _confirmDeleteAccount(context, lang),
            icon: const Icon(Icons.delete_forever_rounded, size: 20),
            label: Text(
              AppStrings.get('btn_delete_account', lang),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _C.danger,
              side: const BorderSide(color: Color(0xFFFFCDD2), width: 1.2),
              backgroundColor: const Color(0xFFFFEBEE).withAlpha(120),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Yardımcı Widget'lar ─────────────────────────

  Widget _buildGroupCard(List<Widget> children) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
        boxShadow: isDark ? [] : _softShadow(),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    final isDark = context.isDark;
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5FD),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? iconColor.withAlpha(50)
                    : iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : _C.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: _C.danger),
            const SizedBox(height: 12),
            const Text(
              'Profil Yüklenemedi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Modallar & Diyaloglar ─────────────────────────

  void _openEditProfileDialog(
    BuildContext context,
    UserProfile profile, [
    String lang = 'tr',
  ]) {
    final nameCtrl = TextEditingController(text: profile.fullName);
    final emailCtrl = TextEditingController(text: profile.email);
    final phoneCtrl = TextEditingController(text: profile.phoneNumber);
    final addrCtrl = TextEditingController(text: profile.address);
    final tcCtrl = TextEditingController(text: profile.tcNo);

    final isDark = context.isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.get('dialog_edit_profile', lang),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : _C.textDark,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  AppStrings.get('field_full_name', lang),
                  nameCtrl,
                  Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  AppStrings.get('field_email', lang),
                  emailCtrl,
                  Icons.email_outlined,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  AppStrings.get('field_phone', lang),
                  phoneCtrl,
                  Icons.phone_outlined,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  AppStrings.get('field_tc', lang),
                  tcCtrl,
                  Icons.badge_outlined,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  AppStrings.get('field_address', lang),
                  addrCtrl,
                  Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(profileServiceProvider)
                          .updateProfile(
                            fullName: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            phoneNumber: phoneCtrl.text.trim(),
                            address: addrCtrl.text.trim(),
                            neighborhood: profile.neighborhood,
                            tcNo: tcCtrl.text.trim(),
                          );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      _showSnackBar(
                        AppStrings.get('profile_updated_toast', lang),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      AppStrings.get('btn_save', lang),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      nameCtrl.dispose();
      emailCtrl.dispose();
      phoneCtrl.dispose();
      addrCtrl.dispose();
      tcCtrl.dispose();
    });
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    int maxLines = 1,
  }) {
    final isDark = context.isDark;
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : null),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: isDark ? const Color(0xFF60A5FA) : _C.navy,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF60A5FA) : _C.navy,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  void _openNeighborhoodPicker(
    BuildContext context,
    UserProfile profile, [
    String lang = 'tr',
  ]) {
    final isDark = context.isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.get('dialog_select_neighborhood', lang),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : _C.textDark,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              Text(
                AppStrings.get('select_neighborhood_sub', lang),
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: _kGebzeNeighborhoods.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5FD),
                  ),
                  itemBuilder: (context, index) {
                    final n = _kGebzeNeighborhoods[index];
                    final isSelected =
                        profile.neighborhood.toLowerCase() == n.toLowerCase();

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      title: Text(
                        '$n ${AppStrings.get('mahalle_suffix', lang)}',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? (isDark ? const Color(0xFF60A5FA) : _C.navy)
                              : (isDark ? Colors.white : _C.textDark),
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: isDark ? const Color(0xFF60A5FA) : _C.navy,
                            )
                          : null,
                      onTap: () async {
                        await ref
                            .read(profileServiceProvider)
                            .updateNeighborhood(n);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        _showSnackBar(
                          AppStrings.get('neighborhood_updated_toast', lang),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openNotificationPreferences(
    BuildContext context,
    UserProfile profile,
    String lang,
  ) {
    final isDark = context.isDark;
    final prefs = Map<String, bool>.from(profile.notificationPreferences);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.get('tile_notifications', lang),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : _C.textDark,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSwitchTile(
                    AppStrings.get('notif_push', lang),
                    prefs['push'] ?? true,
                    (v) {
                      setModalState(() => prefs['push'] = v);
                      ref
                          .read(profileServiceProvider)
                          .updateNotificationPreference('push', v);
                    },
                  ),
                  _buildSwitchTile(
                    AppStrings.get('notif_sms', lang),
                    prefs['sms'] ?? true,
                    (v) {
                      setModalState(() => prefs['sms'] = v);
                      ref
                          .read(profileServiceProvider)
                          .updateNotificationPreference('sms', v);
                    },
                  ),
                  _buildSwitchTile(
                    AppStrings.get('notif_outages', lang),
                    prefs['outages'] ?? true,
                    (v) {
                      setModalState(() => prefs['outages'] = v);
                      ref
                          .read(profileServiceProvider)
                          .updateNotificationPreference('outages', v);
                    },
                  ),
                  _buildSwitchTile(
                    AppStrings.get('notif_emergency', lang),
                    prefs['emergency'] ?? true,
                    (v) {
                      setModalState(() => prefs['emergency'] = v);
                      ref
                          .read(profileServiceProvider)
                          .updateNotificationPreference('emergency', v);
                    },
                  ),
                  _buildSwitchTile(
                    AppStrings.get('notif_soz_sende', lang),
                    prefs['sozSende'] ?? true,
                    (v) {
                      setModalState(() => prefs['sozSende'] = v);
                      ref
                          .read(profileServiceProvider)
                          .updateNotificationPreference('sozSende', v);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool val,
    ValueChanged<bool> onChanged,
  ) {
    final isDark = context.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : _C.textDark,
              ),
            ),
          ),
          Switch.adaptive(
            value: val,
            activeThumbColor: _C.navy,
            activeTrackColor: const Color(0xFF90CAF9),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _openActivitiesSheet(
    BuildContext context,
    String initialType, [
    String lang = 'tr',
  ]) {
    final isDark = context.isDark;
    final activitiesStream = ref
        .read(profileServiceProvider)
        .getActivitiesStream();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DefaultTabController(
          length: 4,
          initialIndex: initialType == 'oneri'
              ? 1
              : initialType == 'destek'
              ? 2
              : initialType == 'kayit'
              ? 3
              : 0,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.78,
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.get('section_activities', lang),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : _C.textDark,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: isDark ? const Color(0xFF60A5FA) : _C.navy,
                  unselectedLabelColor: isDark
                      ? const Color(0xFF94A3B8)
                      : _C.textMuted,
                  indicatorColor: isDark ? const Color(0xFF60A5FA) : _C.navy,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: AppStrings.get('stat_requests', lang)),
                    Tab(text: AppStrings.get('stat_suggestions', lang)),
                    Tab(text: AppStrings.get('stat_supports', lang)),
                    Tab(text: AppStrings.get('stat_saved', lang)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<List<UserActivityItem>>(
                    stream: activitiesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError &&
                          (!snapshot.hasData || snapshot.data!.isEmpty)) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 40,
                                color: Color(0xFFEF4444),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppStrings.get('btn_retry', lang),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: _C.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final list = snapshot.data ?? [];
                      return TabBarView(
                        children: [
                          const MyRequestsList(),
                          _buildActivityList(
                            list.where((a) => a.type == 'oneri').toList(),
                            lang,
                          ),
                          _buildActivityList(
                            list.where((a) => a.type == 'destek').toList(),
                            lang,
                          ),
                          _buildActivityList(
                            list.where((a) => a.type == 'kayit').toList(),
                            lang,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityList(
    List<UserActivityItem> items, [
    String lang = 'tr',
  ]) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.inbox_rounded,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 10),
              Text(
                AppStrings.get('no_activities_found', lang),
                style: const TextStyle(
                  fontSize: 14,
                  color: _C.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isDark = context.isDark;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = items[i];
        Color statusColor;
        switch (item.status.toLowerCase()) {
          case 'çözüldü':
          case 'onaylandı':
          case 'oylandı':
            statusColor = _C.green;
            break;
          case 'işleme alındı':
          case 'yayında':
            statusColor = const Color(0xFF0288D1);
            break;
          default:
            statusColor = _C.orange;
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF60A5FA) : _C.navy)
                          .withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF93C5FD) : _C.navy,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : _C.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.date,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openLanguagePicker(
    BuildContext context,
    UserProfile profile,
    String lang,
  ) {
    final isDark = context.isDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.get('tile_language', lang),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : _C.textDark,
                ),
              ),
              const SizedBox(height: 14),
              _buildLanguageItem('Türkçe', 'tr', '🇹🇷', lang, (code) {
                ref.read(appLanguageProvider.notifier).setLanguage(code);
                ref.read(profileServiceProvider).updateLanguage(code);
                Navigator.of(ctx).pop();
                _showSnackBar(AppStrings.get('lang_tr_selected', code));
              }),
              _buildLanguageItem('English', 'en', '🇬🇧', lang, (code) {
                ref.read(appLanguageProvider.notifier).setLanguage(code);
                ref.read(profileServiceProvider).updateLanguage(code);
                Navigator.of(ctx).pop();
                _showSnackBar(AppStrings.get('lang_en_selected', code));
              }),
              _buildLanguageItem('العربية', 'ar', '🇸🇦', lang, (code) {
                ref.read(appLanguageProvider.notifier).setLanguage(code);
                ref.read(profileServiceProvider).updateLanguage(code);
                Navigator.of(ctx).pop();
                _showSnackBar(AppStrings.get('lang_ar_selected', code));
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageItem(
    String label,
    String code,
    String flag,
    String currentCode,
    ValueChanged<String> onSelect,
  ) {
    final isDark = context.isDark;
    final isSelected = currentCode == code;

    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected
              ? (isDark ? const Color(0xFF60A5FA) : _C.navy)
              : (isDark ? Colors.white : _C.textDark),
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle_rounded,
              color: isDark ? const Color(0xFF60A5FA) : _C.navy,
            )
          : null,
      onTap: () => onSelect(code),
    );
  }

  void _openThemePicker(
    BuildContext context,
    UserProfile profile, [
    String lang = 'tr',
  ]) {
    final isDark = context.isDark;
    final currentAppTheme = ref.read(appThemeModeProvider);
    final activeThemeStr = currentAppTheme == ThemeMode.dark
        ? 'dark'
        : (currentAppTheme == ThemeMode.system ? 'system' : 'light');

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.get('theme_picker_title', lang),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : _C.textDark,
                ),
              ),
              const SizedBox(height: 14),
              _buildThemeOption(
                AppStrings.get('theme_light', lang),
                'light',
                Icons.light_mode_rounded,
                activeThemeStr,
                lang,
              ),
              _buildThemeOption(
                AppStrings.get('theme_dark', lang),
                'dark',
                Icons.dark_mode_rounded,
                activeThemeStr,
                lang,
              ),
              _buildThemeOption(
                AppStrings.get('theme_system', lang),
                'system',
                Icons.phone_android_rounded,
                activeThemeStr,
                lang,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    String label,
    String mode,
    IconData icon,
    String currentMode, [
    String lang = 'tr',
  ]) {
    final isDark = context.isDark;
    final isSelected = currentMode == mode;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? (isDark ? const Color(0xFF60A5FA) : _C.navy)
            : (isDark ? const Color(0xFF94A3B8) : _C.textMuted),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected
              ? (isDark ? const Color(0xFF60A5FA) : _C.navy)
              : (isDark ? Colors.white : _C.textDark),
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle_rounded,
              color: isDark ? const Color(0xFF60A5FA) : _C.navy,
            )
          : null,
      onTap: () {
        ref.read(appThemeModeProvider.notifier).setThemeMode(mode);
        ref.read(profileServiceProvider).updateThemeMode(mode);
        Navigator.of(context).pop();
        _showSnackBar(AppStrings.get('theme_updated_toast', lang));
      },
    );
  }

  void _openAvatarPicker(
    BuildContext context,
    UserProfile profile, [
    String lang = 'tr',
  ]) {
    GebzeAvatarPickerSheet.show(
      context,
      currentAvatarUrl: profile.avatarUrl,
      onAvatarSelected: (selectedUrl) async {
        await ref.read(profileServiceProvider).updateAvatarUrl(selectedUrl);
        if (context.mounted) {
          _showSnackBar(AppStrings.get('avatar_updated_toast', lang));
        }
      },
    );
  }

  void _confirmSignOut(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            AppStrings.get('btn_logout', lang),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(AppStrings.get('confirm_signout_msg', lang)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.get('btn_cancel', lang)),
            ),
            ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                Navigator.of(ctx).pop();
                await ref.read(authServiceProvider).signOut();
                ref.read(guestModeProvider.notifier).state = false;
                if (mounted) nav.popUntil((r) => r.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.navy,
                foregroundColor: Colors.white,
              ),
              child: Text(AppStrings.get('btn_logout', lang)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: _C.danger,
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.get('btn_delete_account', lang),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _C.danger,
                ),
              ),
            ],
          ),
          content: Text(
            AppStrings.get('confirm_delete_msg', lang),
            style: const TextStyle(fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.get('dismiss', lang)),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref.read(profileServiceProvider).deleteAccount();
                if (ctx.mounted) Navigator.of(ctx).pop();
                _showSnackBar(AppStrings.get('account_deleted_msg', lang));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.danger,
                foregroundColor: Colors.white,
              ),
              child: Text(AppStrings.get('btn_confirm_delete', lang)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _callMunicipalCallCenter([String lang = 'tr']) async {
    final uri = Uri.parse('tel:4440153');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnackBar(
        AppStrings.get(
          'call_failed_toast',
          lang,
        ).replaceAll('{0}', '444 0 153'),
      );
    }
  }

  void _openPrivacySheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KVKK ve Gizlilik Politikası',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : _C.textDark,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'Gebze Belediyesi olarak, 6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") kapsamında vatandaşlarımızın kişisel verilerinin güvenliğini en üst düzeyde korumayı taahhüt ediyoruz.\n\n'
                    '1. Veri Sorumlusu: Gebze Belediyesi Başkanlığı.\n'
                    '2. İşlenen Veriler: Ad, soyad, T.C. kimlik numarası, telefon, adres ve mahalle bilgileri.\n'
                    '3. Veri İşleme Amacı: Belediye hizmetlerinin hızlı, verimli ve dijital olarak vatandaşlara ulaştırılması, acil durum bildirimlerinin iletilmesi.\n'
                    '4. Veri Aktarımı: Verileriniz üçüncü şahıslarla ticari amaçla paylaşılmaz, yalnızca yasal zorunluluk hallerinde yetkili kamu kurumlarıyla paylaşılabilir.\n'
                    '5. Haklarınız: KVKK Madde 11 uyarınca dilediğiniz zaman verilerinizin güncellenmesini, silinmesini veya işlenip işlenmediğini öğrenmeyi talep edebilirsiniz.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? const Color(0xFF94A3B8) : _C.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: _C.navy,
      ),
    );
  }
}

// ───────────────────────── Alt Gezinme Barı ─────────────────────────

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

class _BottomNav extends ConsumerWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
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

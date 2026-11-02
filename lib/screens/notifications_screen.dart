import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'emergency_screen.dart';
import 'guide_screen.dart';
import 'outages_screen.dart';
import 'my_requests_screen.dart';
import 'neighborhood_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'services_screen.dart';
import 'soz_sende_screen.dart';
import '../features/ebelediye/presentation/ebelediye_screen.dart';
import '../features/news/municipal_news_screen.dart';
import '../features/parking/presentation/parking_screen.dart';
import '../features/weather/presentation/weather_screen.dart';
import '../features/pharmacy/presentation/pharmacies_screen.dart';
import '../features/pati/presentation/gebze_pati_screen.dart';
import '../core/services/notification_service.dart';

export '../core/services/notification_service.dart'
    show
        AppNotification,
        NotificationCategory,
        notificationsProvider,
        unreadNotificationsCountProvider;

class _C {
  static const Color navy = Color(0xFF0A2A66);
  static const Color navyDeep = Color(0xFF061A40);
  static const Color blueLight = Color(0xFF1E5BC6);
  static const Color orange = Color(0xFFFF6B00);
  static const Color bg = Color(0xFFF6F8FC);
  static const Color textDark = Color(0xFF1A1D20);
  static const Color textMuted = Color(0xFF757575);
  static const Color border = Color(0xFFE3E8F0);
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  /// Bildirimdeki `actionType` (hedef sayfa / kategori) bilgisine göre ilgili ekranı açar.
  /// Doğrudan bir sayfaya yönlendirme yapıldıysa `true`, sadece detay gösterilecekse `false` döner.
  static Future<bool> navigateToTarget(
    NavigatorState nav,
    AppNotification item,
  ) async {
    Widget? targetWidget;

    switch (item.actionType) {
      case 'home':
        nav.popUntil((route) => route.isFirst);
        return true;
      case 'outages':
        targetWidget = const OutagesScreen();
        break;
      case 'emergency':
        targetWidget = const EmergencyScreen();
        break;
      case 'neighborhood':
        targetWidget = const NeighborhoodScreen();
        break;
      case 'pharmacy':
        targetWidget = const PharmaciesScreen();
        break;
      case 'parking':
        targetWidget = const ParkingScreen();
        break;
      case 'sozSende':
        targetWidget = const SozSendeScreen();
        break;
      case 'report':
        targetWidget = const ReportScreen();
        break;
      case 'requests':
        targetWidget = const MyRequestsScreen();
        break;
      case 'ebelediye':
        targetWidget = const EBelediyeScreen();
        break;
      case 'services':
        targetWidget = const ServicesScreen();
        break;
      case 'weather':
        targetWidget = const WeatherScreen();
        break;
      case 'news':
        targetWidget = const MunicipalNewsScreen();
        break;
      case 'profile':
        targetWidget = const ProfileScreen();
        break;
      // Şehir Rehberi & Kurumsal Tesis Kategorileri
      case 'guide_institutions':
        targetWidget = const GuideScreen(initialTab: 0);
        break;
      case 'guide_etkinlikler':
      case 'events':
        targetWidget = const GuideCategoryScreen(categoryId: 'etkinlikler');
        break;
      case 'guide_lokantalar':
      case 'food':
        targetWidget = const GuideCategoryScreen(categoryId: 'lokantalar');
        break;
      case 'guide_parklar':
        targetWidget = const GuideCategoryScreen(categoryId: 'parklar');
        break;
      case 'guide_pazar':
        targetWidget = const GuideCategoryScreen(categoryId: 'pazar');
        break;
      case 'guide_spor':
        targetWidget = const GuideCategoryScreen(categoryId: 'spor');
        break;
      case 'guide_kultur':
        targetWidget = const GuideCategoryScreen(categoryId: 'kultur');
        break;
      case 'guide_kresler':
        targetWidget = const GuideCategoryScreen(categoryId: 'kresler');
        break;
      case 'guide_mezarliklar':
        targetWidget = const GuideCategoryScreen(categoryId: 'mezarliklar');
        break;
      case 'guide_belediye':
        targetWidget = const GuideCategoryScreen(categoryId: 'belediye');
        break;
      // Gebze'yi Keşfet Alt Bölümleri
      case 'discover_places':
        targetWidget = const GuideScreen(
          initialTab: 1,
          initialDiscoverSection: 0,
        );
        break;
      case 'discover_foods':
        targetWidget = const GuideScreen(
          initialTab: 1,
          initialDiscoverSection: 1,
        );
        break;
      case 'discover_picnic':
        targetWidget = const GuideScreen(
          initialTab: 1,
          initialDiscoverSection: 2,
        );
        break;
      // Gebze Pati Alt Sekmeleri
      case 'pati_center':
        targetWidget = const GebzePatiScreen(initialIndex: 0);
        break;
      case 'pati_adoption':
      case 'pati':
        targetWidget = const GebzePatiScreen(initialIndex: 1);
        break;
      case 'pati_feeding':
        targetWidget = const GebzePatiScreen(initialIndex: 2);
        break;
      // Harici Web Bağlantısı
      case 'external_url':
        final urlStr = item.externalUrl?.trim() ?? '';
        if (urlStr.isNotEmpty) {
          final uri = Uri.tryParse(urlStr);
          if (uri != null) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            ).catchError((_) => false);
            return true;
          }
        }
        return false;
      case 'detail_only':
      case 'announcements':
      default:
        return false;
    }

    nav.push(MaterialPageRoute(builder: (_) => targetWidget!));
    return true;
  }

  /// Canlı In-App Banner (SnackBar) üzerinden tıklandığında hedef sayfaya veya bildirim ekranına yönlendirir.
  static Future<void> navigateFromBanner(
    GlobalKey<NavigatorState> navigatorKey,
    AppNotification item,
  ) async {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    final routed = await navigateToTarget(nav, item);
    if (!routed) {
      nav.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    }
  }

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationCategory _selectedCategory = NotificationCategory.all;

  void _markAllAsRead() {
    ref.read(notificationsProvider.notifier).markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tüm bildirimler okundu olarak işaretlendi.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleNotificationTap(AppNotification item) async {
    ref.read(notificationsProvider.notifier).markAsRead(item.id);

    final nav = Navigator.of(context);
    final navigated = await NotificationsScreen.navigateToTarget(nav, item);
    if (!navigated && mounted) {
      _showNotificationDetail(item);
    }
  }

  void _showNotificationDetail(AppNotification item) {
    ref.read(notificationsProvider.notifier).markAsRead(item.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: item.color, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0A2A66),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                item.time,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                              if (item.neighborhood != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _C.blueLight.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '📍 ${item.neighborhood}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _C.blueLight,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (item.imageUrl != null &&
                    item.imageUrl!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    item.message,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.5,
                      color: isDark
                          ? Colors.grey[200]
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (item.hasDirectNavigation) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        NotificationsScreen.navigateToTarget(
                          Navigator.of(context),
                          item,
                        );
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(
                        item.actionButtonLabel ??
                            '${item.effectiveTargetLabel} Sayfasına Git',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A2A66),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Anladım',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final filtered = notifications.where((n) {
      if (_selectedCategory == NotificationCategory.all) return true;
      return n.category == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : _C.bg,
      body: Column(
        children: [
          // 32px Oval Curved Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + 10,
              left: 16,
              right: 16,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.navy, _C.navyDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Material(
                  color: Colors.white12,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'BİLDİRİMLER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        unreadCount > 0
                            ? '$unreadCount okunmamış bildirim'
                            : 'Gebze Belediyesi ve Şehir Duyuruları',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tümünü Okundu Say',
                  icon: const Icon(
                    Icons.done_all_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: _markAllAsRead,
                ),
              ],
            ),
          ),

          // Category Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('Tümü', NotificationCategory.all, isDark),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Kesintiler',
                  NotificationCategory.outages,
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Duyurular',
                  NotificationCategory.announcements,
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Hizmetler',
                  NotificationCategory.services,
                  isDark,
                ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : _C.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bu kategoride bildirim bulunmuyor.',
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : _C.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _NotificationCard(
                        notification: item,
                        isDark: isDark,
                        onTap: () => _handleNotificationTap(item),
                        onDetailTap: () => _showNotificationDetail(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, NotificationCategory cat, bool isDark) {
    final isSelected = _selectedCategory == cat;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2563EB) : _C.navy)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF2563EB) : _C.navy)
                : (isDark ? const Color(0xFF334155) : _C.border),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _C.navy.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : _C.textDark),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDetailTap;

  const _NotificationCard({
    required this.notification,
    this.isDark = false,
    required this.onTap,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = notification.priority == 'urgent';
    final isImportant = notification.priority == 'important';

    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: notification.isRead ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUrgent && !notification.isRead
                  ? const Color(0xFFD32F2F).withValues(alpha: 0.5)
                  : notification.isRead
                  ? (isDark
                        ? const Color(0xFF334155)
                        : _C.border.withValues(alpha: 0.6))
                  : (isDark
                        ? const Color(0xFF3B82F6)
                        : _C.navy.withValues(alpha: 0.25)),
              width: notification.isRead ? 1 : 1.4,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notification.color.withValues(
                    alpha: isDark ? 0.2 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isUrgent ||
                        isImportant ||
                        notification.neighborhood != null) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (isUrgent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD32F2F),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '🚨 ACİL DUYURU',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )
                          else if (isImportant)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _C.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '⚡ ÖNEMLİ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          if (notification.neighborhood != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _C.blueLight.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '📍 ${notification.neighborhood}',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF93C5FD)
                                      : _C.blueLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: notification.isRead
                                  ? FontWeight.w700
                                  : FontWeight.w900,
                              color: isDark ? Colors.white : _C.textDark,
                            ),
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _C.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: notification.isRead
                            ? (isDark ? const Color(0xFF94A3B8) : _C.textMuted)
                            : (isDark ? const Color(0xFFCBD5E1) : _C.textDark),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : _C.textMuted.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notification.time,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : _C.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (notification.hasDirectNavigation)
                          InkWell(
                            onTap: onDetailTap,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Text(
                                'Metni Oku',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : _C.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            notification.actionButtonLabel ??
                                (notification.hasDirectNavigation
                                    ? notification.effectiveTargetLabel
                                    : 'Detaylar'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF60A5FA)
                                  : _C.blueLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: isDark
                              ? const Color(0xFF60A5FA)
                              : _C.blueLight,
                        ),
                      ],
                    ),
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

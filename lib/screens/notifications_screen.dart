import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'emergency_screen.dart';
import 'guide_screen.dart';
import 'outages_screen.dart';
import 'my_requests_screen.dart';
import '../features/weather/presentation/weather_screen.dart';
import '../features/pharmacy/presentation/pharmacies_screen.dart';
import '../features/pati/presentation/gebze_pati_screen.dart';

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

enum NotificationCategory { all, outages, announcements, services }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  final NotificationCategory category;
  final VoidCallback? onTap;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    required this.category,
    this.onTap,
    this.isRead = false,
  });
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationCategory _selectedCategory = NotificationCategory.all;

  late List<AppNotification> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      AppNotification(
        id: '1',
        title: 'Planlı Su Kesintisi Bildirimi',
        message: 'Yenikent ve Gaziler Mahallelerinde 14:00 - 18:00 saatleri arasında şebeke iyileştirme çalışması yapılacaktır.',
        time: '15 dk önce',
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF0288D1),
        category: NotificationCategory.outages,
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const OutagesScreen())),
      ),
      AppNotification(
        id: '2',
        title: 'Gebze Afet & Acil Toplanma Alanları',
        message: 'Mahallenizdeki en yakın güvenli toplanma alanları ve acil durum irtibat numaraları güncellendi.',
        time: '1 saat önce',
        icon: Icons.emergency_rounded,
        color: const Color(0xFFD32F2F),
        category: NotificationCategory.announcements,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const EmergencyScreen())),
      ),
      AppNotification(
        id: '3',
        title: 'Bu Gece Nöbetçi Eczaneler',
        message: 'Gebze merkez ve istasyon bölgelerinde açık olan nöbetçi eczaneleri inceleyebilirsiniz.',
        time: '3 saat önce',
        icon: Icons.local_pharmacy_rounded,
        color: const Color(0xFF2E7D32),
        category: NotificationCategory.services,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PharmaciesScreen(),
          ),
        ),
      ),
      AppNotification(
        id: '4',
        title: 'Kent Lokantası Sıcak Menü Servisi',
        message: 'Bugünün 4 çeşit sağlıklı menüsü Gebze Kent Lokantalarında servis edilmeye başlandı.',
        time: '5 saat önce',
        icon: Icons.restaurant_rounded,
        color: const Color(0xFFFF6B00),
        category: NotificationCategory.services,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const GuideCategoryScreen(categoryId: 'lokantalar'),
          ),
        ),
      ),
      AppNotification(
        id: '5',
        title: 'Gebze Pati Sahiplendirme Günü',
        message: 'Sokak hayvanları bakım merkezimizdeki can dostlarımız bu Pazar Cumhuriyet Meydanı\'nda yuva arıyor.',
        time: 'Dün',
        icon: Icons.pets_rounded,
        color: const Color(0xFF7B1FA2),
        category: NotificationCategory.announcements,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const GebzePatiScreen(initialIndex: 1),
          ),
        ),
      ),
      AppNotification(
        id: '6',
        title: 'Çek / Bildir Talebiniz İncelendi',
        message: 'Belediyemize ilettiğiniz talep ilgili saha müdürlüğüne yönlendirilmiş olup işlem sırasına alınmıştır.',
        time: '2 gün önce',
        icon: Icons.assignment_turned_in_rounded,
        color: const Color(0xFF1E5BC6),
        category: NotificationCategory.services,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const MyRequestsScreen())),
        isRead: true,
      ),
      AppNotification(
        id: '7',
        title: 'Hava Durumu Bilgilendirmesi',
        message: 'Gebze genelinde yarın kuvvetli yağış beklenmektedir. Tedbirli olunması rica olunur.',
        time: '3 gün önce',
        icon: Icons.cloud_outlined,
        color: const Color(0xFF455A64),
        category: NotificationCategory.announcements,
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const WeatherScreen())),
        isRead: true,
      ),
    ];
  }

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tüm bildirimler okundu olarak işaretlendi.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _notifications.where((n) {
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
                        'Gebze Belediyesi ve Şehir Duyuruları',
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
                        onTap: () {
                          setState(() => item.isRead = true);
                          item.onTap?.call();
                        },
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

  const _NotificationCard({
    required this.notification,
    this.isDark = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              color: notification.isRead
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
                        Text(
                          'Detaylar',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF60A5FA)
                                : _C.blueLight,
                            fontWeight: FontWeight.w700,
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

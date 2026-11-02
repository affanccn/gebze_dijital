import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'push_service.dart';

enum NotificationCategory { all, outages, announcements, services }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  final NotificationCategory category;
  final String actionType;
  final String? targetLabel;
  final String? actionButtonLabel;
  final String? externalUrl;
  final String? imageUrl;
  final String priority; // 'normal', 'important', 'urgent'
  final String? neighborhood;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    required this.category,
    required this.actionType,
    this.targetLabel,
    this.actionButtonLabel,
    this.externalUrl,
    this.imageUrl,
    this.priority = 'normal',
    this.neighborhood,
    this.isRead = false,
  });

  bool get hasDirectNavigation =>
      actionType.isNotEmpty &&
      actionType != 'detail_only' &&
      actionType != 'announcements';

  String get effectiveTargetLabel =>
      (targetLabel != null && targetLabel!.trim().isNotEmpty)
          ? targetLabel!.trim()
          : NotificationService.labelForActionType(actionType);

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? time,
    IconData? icon,
    Color? color,
    NotificationCategory? category,
    String? actionType,
    String? targetLabel,
    String? actionButtonLabel,
    String? externalUrl,
    String? imageUrl,
    String? priority,
    String? neighborhood,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      category: category ?? this.category,
      actionType: actionType ?? this.actionType,
      targetLabel: targetLabel ?? this.targetLabel,
      actionButtonLabel: actionButtonLabel ?? this.actionButtonLabel,
      externalUrl: externalUrl ?? this.externalUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      priority: priority ?? this.priority,
      neighborhood: neighborhood ?? this.neighborhood,
      isRead: isRead ?? this.isRead,
    );
  }
}

const String kNotificationApiBaseUrl =
    'https://api.gebze.bel.tr/api/v1/notifications';
const String _kReadNotificationsKey = 'gebze_read_notification_ids_v1';

class NotificationService {
  NotificationService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static String labelForActionType(String actionType) {
    switch (actionType) {
      case 'home':
        return 'Ana Sayfa';
      case 'news':
        return 'Haberler & Duyurular';
      case 'outages':
        return 'Planlı Kesintiler';
      case 'emergency':
        return 'Afet & Toplanma Alanları';
      case 'neighborhood':
        return 'Mahallemde Çalışmalar';
      case 'pharmacy':
        return 'Nöbetçi Eczaneler';
      case 'parking':
        return 'Otoparklar & Doluluk';
      case 'sozSende':
        return 'Söz Sende & Anketler';
      case 'report':
        return 'Çek & Gönder (Talep Oluştur)';
      case 'requests':
        return 'Başvurularım & Talep Takip';
      case 'ebelediye':
        return 'E-Belediye Hizmetleri';
      case 'services':
        return 'Tüm Belediye Hizmetleri';
      case 'weather':
        return 'Hava Durumu';
      case 'profile':
        return 'Profil & Ayarlar';
      case 'guide_institutions':
        return 'Şehir Rehberi (Kurumsal)';
      case 'guide_etkinlikler':
      case 'events':
        return 'Kültür & Sanat Etkinlikleri';
      case 'guide_lokantalar':
      case 'food':
        return 'Kent Lokantaları';
      case 'guide_parklar':
        return 'Parklar & Yeşil Alanlar';
      case 'guide_pazar':
        return 'Semt Pazar Yerleri';
      case 'guide_spor':
        return 'Spor Tesisleri';
      case 'guide_kultur':
        return 'Kültür Merkezleri & Kütüphaneler';
      case 'guide_kresler':
        return 'Kreşler & Çocuk Atölyeleri';
      case 'guide_mezarliklar':
        return 'Mezarlıklar & Defin Hizmetleri';
      case 'guide_belediye':
        return 'Belediye Hizmet Birimleri';
      case 'discover_places':
        return 'Gebze\'yi Keşfet: Tarihi Yerler';
      case 'discover_foods':
        return 'Gebze\'yi Keşfet: Yöresel Lezzetler';
      case 'discover_picnic':
        return 'Gebze\'yi Keşfet: Doğa & Piknik';
      case 'pati_center':
        return 'Gebze Pati: Bakım Merkezi & Ambulans';
      case 'pati_adoption':
      case 'pati':
        return 'Gebze Pati: Yuva Arayanlar';
      case 'pati_feeding':
        return 'Gebze Pati: Mama & Veteriner';
      case 'external_url':
        return 'Web Bağlantısı';
      case 'detail_only':
      case 'announcements':
      default:
        return 'Duyuru Detayı';
    }
  }

  /// Bildirimi API üzerinde okundu olarak işaretler (API PATCH).
  Future<bool> patchNotificationAsRead(String notificationId) async {
    try {
      final uri = Uri.parse('$kNotificationApiBaseUrl/$notificationId/read');
      final response = await _client
          .patch(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'notificationId': notificationId,
              'isRead': true,
              'readAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 4));

      debugPrint(
        '[API PATCH] Bildirim $notificationId okundu: ${response.statusCode}',
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint(
        '[API PATCH] Bildirim $notificationId güncelleme isteği yapıldı: $e',
      );
      return false;
    }
  }

  /// Tüm bildirimleri API üzerinde okundu olarak işaretler (API PATCH).
  Future<bool> patchAllNotificationsAsRead(List<String> notificationIds) async {
    try {
      final uri = Uri.parse('$kNotificationApiBaseUrl/read-all');
      final response = await _client
          .patch(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'notificationIds': notificationIds,
              'isRead': true,
              'readAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 4));

      debugPrint('[API PATCH] Tüm bildirimler okundu: ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('[API PATCH] Tüm bildirimler güncelleme isteği yapıldı: $e');
      return false;
    }
  }
}

class NotificationsNotifier extends Notifier<List<AppNotification>> {
  final NotificationService _service = NotificationService();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  bool _isInitialLoadDone = false;

  /// Canlı gelen duyuruları arayüzde (In-App Banner/SnackBar) göstermek için callback
  static void Function(AppNotification notification)? onInAppNotification;

  static List<AppNotification> get _initialNotifications => [
    const AppNotification(
      id: '1',
      title: 'Planlı Su Kesintisi Bildirimi',
      message:
          'Yenikent ve Gaziler Mahallelerinde 14:00 - 18:00 saatleri arasında şebeke iyileştirme çalışması yapılacaktır.',
      time: '15 dk önce',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF0288D1),
      category: NotificationCategory.outages,
      actionType: 'outages',
      targetLabel: 'Planlı Kesintiler',
      priority: 'important',
    ),
    const AppNotification(
      id: '2',
      title: 'Gebze Afet & Acil Toplanma Alanları',
      message:
          'Mahallenizdeki en yakın güvenli toplanma alanları ve acil durum irtibat numaraları güncellendi.',
      time: '1 saat önce',
      icon: Icons.emergency_rounded,
      color: Color(0xFFD32F2F),
      category: NotificationCategory.announcements,
      actionType: 'emergency',
      targetLabel: 'Afet & Toplanma Alanları',
      priority: 'urgent',
    ),
    const AppNotification(
      id: '3',
      title: 'Bu Gece Nöbetçi Eczaneler',
      message:
          'Gebze merkez ve istasyon bölgelerinde açık olan nöbetçi eczaneleri inceleyebilirsiniz.',
      time: '3 saat önce',
      icon: Icons.local_pharmacy_rounded,
      color: Color(0xFF2E7D32),
      category: NotificationCategory.services,
      actionType: 'pharmacy',
      targetLabel: 'Nöbetçi Eczaneler',
    ),
    const AppNotification(
      id: '4',
      title: 'Kent Lokantası Sıcak Menü Servisi',
      message:
          'Bugünün 4 çeşit sağlıklı menüsü Gebze Kent Lokantalarında servis edilmeye başlandı.',
      time: '5 saat önce',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFF6B00),
      category: NotificationCategory.services,
      actionType: 'guide_lokantalar',
      targetLabel: 'Kent Lokantaları',
    ),
    const AppNotification(
      id: '5',
      title: 'Gebze Pati Sahiplendirme Günü',
      message:
          'Sokak hayvanları bakım merkezimizdeki can dostlarımız bu Pazar Cumhuriyet Meydanı\'nda yuva arıyor.',
      time: 'Dün',
      icon: Icons.pets_rounded,
      color: Color(0xFF7B1FA2),
      category: NotificationCategory.announcements,
      actionType: 'pati_adoption',
      targetLabel: 'Gebze Pati: Yuva Arayanlar',
    ),
    const AppNotification(
      id: '6',
      title: 'Çek / Bildir Talebiniz İncelendi',
      message:
          'Belediyemize ilettiğiniz talep ilgili saha müdürlüğüne yönlendirilmiş olup işlem sırasına alınmıştır.',
      time: '2 gün önce',
      icon: Icons.assignment_turned_in_rounded,
      color: Color(0xFF1E5BC6),
      category: NotificationCategory.services,
      actionType: 'requests',
      targetLabel: 'Başvurularım & Talep Takip',
      isRead: true,
    ),
    const AppNotification(
      id: '7',
      title: 'Hava Durumu Bilgilendirmesi',
      message:
          'Gebze genelinde yarın kuvvetli yağış beklenmektedir. Tedbirli olunması rica olunur.',
      time: '3 gün önce',
      icon: Icons.cloud_outlined,
      color: Color(0xFF455A64),
      category: NotificationCategory.announcements,
      actionType: 'weather',
      targetLabel: 'Hava Durumu',
      isRead: true,
    ),
  ];

  @override
  List<AppNotification> build() {
    _loadPersistedReadStatus();
    _initFirestoreListener();
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return _initialNotifications;
  }

  /// Firestore `broadcast_notifications` koleksiyonunu canlı dinler
  void _initFirestoreListener() {
    try {
      if (Firebase.apps.isEmpty) return;

      _subscription?.cancel();
      _subscription = FirebaseFirestore.instance
          .collection('broadcast_notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen(
            (snapshot) async {
              await _handleFirestoreSnapshot(snapshot);
            },
            onError: (e) {
              debugPrint(
                '[NotificationsNotifier] Firestore dinleme hatası: $e',
              );
            },
          );
    } catch (e) {
      debugPrint('[NotificationsNotifier] Firestore başlatılamadı: $e');
    }
  }

  AppNotification _docToNotification(
    String id,
    Map<String, dynamic> d, {
    required bool isRead,
    String? overrideTime,
  }) {
    final title =
        (d['title'] as String?)?.trim() ?? 'Gebze Belediyesi Duyurusu';
    final message = (d['message'] as String?)?.trim() ?? '';
    final topic = d['topic'] as String?;
    final category = d['category'] as String?;
    final rawTarget =
        (d['targetPage'] as String? ?? d['actionType'] as String?)?.trim();
    final actionType = (rawTarget != null && rawTarget.isNotEmpty)
        ? rawTarget
        : _mapActionType(topic, category);
    final priority = (d['priority'] as String?)?.trim() ?? 'normal';
    final targetLabel = (d['targetLabel'] as String?)?.trim();
    final actionButtonLabel = (d['actionButtonLabel'] as String?)?.trim();
    final externalUrl = (d['externalUrl'] as String?)?.trim();
    final imageUrl =
        (d['imageUrl'] as String? ?? d['image'] as String?)?.trim();
    final neighborhood = (d['neighborhood'] as String?)?.trim();
    final createdAt = d['createdAt'];
    final createdAtText = d['createdAtText'] as String?;

    return AppNotification(
      id: id,
      title: title,
      message: message,
      time: overrideTime ?? _formatNotificationTime(createdAt, createdAtText),
      icon: _mapIcon(actionType, topic, category, priority),
      color: _mapColor(actionType, topic, category, priority),
      category: _mapCategory(category, topic, actionType),
      actionType: actionType,
      targetLabel: (targetLabel != null && targetLabel.isNotEmpty)
          ? targetLabel
          : NotificationService.labelForActionType(actionType),
      actionButtonLabel:
          (actionButtonLabel != null && actionButtonLabel.isNotEmpty)
              ? actionButtonLabel
              : null,
      externalUrl:
          (externalUrl != null && externalUrl.isNotEmpty) ? externalUrl : null,
      imageUrl: (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
      priority: priority,
      neighborhood:
          (neighborhood != null &&
                  neighborhood.isNotEmpty &&
                  neighborhood != 'all')
              ? neighborhood
              : null,
      isRead: isRead,
    );
  }

  Future<void> _handleFirestoreSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList(_kReadNotificationsKey) ?? [];

      final List<AppNotification> firestoreItems = [];

      for (final doc in snapshot.docs) {
        final d = doc.data();
        final id = doc.id;
        final isRead = readIds.contains(id);
        firestoreItems.add(_docToNotification(id, d, isRead: isRead));
      }

      // Başlangıç mock listesindeki çakışmayanları koru
      final existingInitial = _initialNotifications
          .where((n) => !firestoreItems.any((fn) => fn.id == n.id))
          .map((n) {
            if (readIds.contains(n.id)) return n.copyWith(isRead: true);
            return n;
          })
          .toList();

      state = [...firestoreItems, ...existingInitial];

      // Uygulama açıkken panele yeni bir bildirim eklendiyse in-app banner göster
      if (_isInitialLoadDone) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final d = change.doc.data();
            if (d != null) {
              final id = change.doc.id;
              final topic = d['topic'] as String?;
              final category = d['category'] as String?;
              final isAllowed = await PushService.isNotificationAllowed(
                type: topic,
                category: category,
              );
              if (isAllowed) {
                final newNotif = _docToNotification(
                  id,
                  d,
                  isRead: false,
                  overrideTime: 'Az önce',
                );
                onInAppNotification?.call(newNotif);
              }
            }
          }
        }
      } else {
        _isInitialLoadDone = true;
      }
    } catch (e) {
      debugPrint('[NotificationsNotifier] Bildirimler işlenirken hata: $e');
    }
  }

  String _formatNotificationTime(dynamic createdAt, String? fallbackText) {
    if (createdAt is Timestamp) {
      final date = createdAt.toDate();
      final diff = DateTime.now().difference(date);
      if (diff.isNegative) return 'Az önce';
      if (diff.inSeconds < 60) return 'Az önce';
      if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
      if (diff.inHours < 24) return '${diff.inHours} saat önce';
      if (diff.inDays == 1) return 'Dün';
      if (diff.inDays < 7) return '${diff.inDays} gün önce';
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
    return fallbackText ?? 'Yeni';
  }

  IconData _mapIcon(
    String actionType,
    String? topic,
    String? category,
    String priority,
  ) {
    switch (actionType) {
      case 'emergency':
        return Icons.emergency_rounded;
      case 'outages':
        return Icons.water_drop_rounded;
      case 'neighborhood':
        return Icons.construction_rounded;
      case 'pharmacy':
        return Icons.local_pharmacy_rounded;
      case 'parking':
        return Icons.local_parking_rounded;
      case 'sozSende':
        return Icons.how_to_vote_rounded;
      case 'report':
        return Icons.add_a_photo_rounded;
      case 'requests':
        return Icons.assignment_turned_in_rounded;
      case 'ebelediye':
        return Icons.account_balance_wallet_rounded;
      case 'services':
        return Icons.grid_view_rounded;
      case 'weather':
        return Icons.wb_cloudy_rounded;
      case 'news':
        return Icons.newspaper_rounded;
      case 'profile':
        return Icons.person_rounded;
      case 'guide_etkinlikler':
      case 'events':
        return Icons.event_available_rounded;
      case 'guide_lokantalar':
      case 'food':
      case 'discover_foods':
        return Icons.restaurant_rounded;
      case 'guide_parklar':
      case 'discover_picnic':
        return Icons.park_rounded;
      case 'guide_pazar':
        return Icons.shopping_basket_rounded;
      case 'guide_spor':
        return Icons.sports_soccer_rounded;
      case 'guide_kultur':
      case 'discover_places':
        return Icons.museum_rounded;
      case 'guide_kresler':
        return Icons.child_care_rounded;
      case 'guide_mezarliklar':
        return Icons.local_florist_rounded;
      case 'guide_belediye':
      case 'guide_institutions':
        return Icons.account_balance_rounded;
      case 'pati_center':
      case 'pati_adoption':
      case 'pati_feeding':
      case 'pati':
        return Icons.pets_rounded;
      case 'external_url':
        return Icons.open_in_new_rounded;
    }
    if (priority == 'urgent' ||
        topic == 'emergency' ||
        category == 'emergency') {
      return Icons.emergency_rounded;
    }
    if (topic == 'outages' || category == 'outages') {
      return Icons.water_drop_rounded;
    }
    if (topic == 'sozSende') {
      return Icons.how_to_vote_rounded;
    }
    if (category == 'services') {
      return Icons.account_balance_rounded;
    }
    return Icons.campaign_rounded;
  }

  Color _mapColor(
    String actionType,
    String? topic,
    String? category,
    String priority,
  ) {
    if (priority == 'urgent') return const Color(0xFFD32F2F);
    switch (actionType) {
      case 'emergency':
        return const Color(0xFFD32F2F);
      case 'outages':
        return const Color(0xFF0288D1);
      case 'neighborhood':
        return const Color(0xFFF57C00);
      case 'pharmacy':
        return const Color(0xFF2E7D32);
      case 'parking':
        return const Color(0xFF1565C0);
      case 'sozSende':
        return const Color(0xFF7B1FA2);
      case 'report':
      case 'requests':
        return const Color(0xFF1E5BC6);
      case 'guide_etkinlikler':
      case 'events':
      case 'guide_lokantalar':
      case 'food':
      case 'discover_foods':
        return const Color(0xFFFF6B00);
      case 'guide_parklar':
      case 'discover_picnic':
        return const Color(0xFF2E7D32);
      case 'guide_kresler':
        return const Color(0xFFEC407A);
      case 'pati_center':
      case 'pati_adoption':
      case 'pati_feeding':
      case 'pati':
        return const Color(0xFF7B1FA2);
    }
    if (topic == 'emergency' || category == 'emergency') {
      return const Color(0xFFD32F2F);
    }
    if (topic == 'outages' || category == 'outages') {
      return const Color(0xFF0288D1);
    }
    if (topic == 'sozSende') {
      return const Color(0xFF7B1FA2);
    }
    if (category == 'services') {
      return const Color(0xFF2E7D32);
    }
    if (priority == 'important') {
      return const Color(0xFFE65100);
    }
    return const Color(0xFF0A2A66);
  }

  NotificationCategory _mapCategory(
    String? category,
    String? topic,
    String actionType,
  ) {
    if (category == 'outages' ||
        topic == 'outages' ||
        actionType == 'outages' ||
        actionType == 'neighborhood') {
      return NotificationCategory.outages;
    }
    if (category == 'services' ||
        actionType == 'pharmacy' ||
        actionType == 'parking' ||
        actionType == 'ebelediye' ||
        actionType == 'services' ||
        actionType.startsWith('guide_')) {
      return NotificationCategory.services;
    }
    return NotificationCategory.announcements;
  }

  String _mapActionType(String? topic, String? category) {
    if (topic == 'emergency') return 'emergency';
    if (topic == 'outages') return 'outages';
    if (topic == 'sozSende') return 'sozSende';
    if (topic == 'news') return 'news';
    if (category == 'outages') return 'outages';
    if (category == 'services') return 'services';
    return 'announcements';
  }

  Future<void> _loadPersistedReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList(_kReadNotificationsKey) ?? [];
      if (readIds.isEmpty) return;

      final updated = state.map((n) {
        if (readIds.contains(n.id)) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      state = updated;
    } catch (e) {
      debugPrint('Bildirim okundu durumları yüklenemedi: $e');
    }
  }

  /// Açılan bildirimi okundu durumuna getirir ve API PATCH isteği gönderir.
  Future<void> markAsRead(String id) async {
    final index = state.indexWhere((n) => n.id == id);
    if (index == -1) return;

    if (state[index].isRead) return; // zaten okundu

    final updated = List<AppNotification>.from(state);
    updated[index] = updated[index].copyWith(isRead: true);
    state = updated;

    // Kalıcı saklama
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList(_kReadNotificationsKey) ?? [];
      if (!readIds.contains(id)) {
        readIds.add(id);
        await prefs.setStringList(_kReadNotificationsKey, readIds);
      }
    } catch (e) {
      debugPrint('Bildirim durumu kaydedilemedi: $e');
    }

    // API PATCH isteği
    await _service.patchNotificationAsRead(id);
  }

  /// Tüm bildirimleri okundu durumuna getirir, rozeti sıfırlar ve API PATCH isteği gönderir.
  Future<void> markAllAsRead() async {
    final unreadIds = state.where((n) => !n.isRead).map((n) => n.id).toList();

    final updated = state.map((n) => n.copyWith(isRead: true)).toList();
    state = updated;

    try {
      final prefs = await SharedPreferences.getInstance();
      final allIds = state.map((n) => n.id).toList();
      await prefs.setStringList(_kReadNotificationsKey, allIds);
    } catch (e) {
      debugPrint('Bildirimler kaydedilemedi: $e');
    }

    if (unreadIds.isNotEmpty) {
      await _service.patchAllNotificationsAsRead(unreadIds);
    }
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<AppNotification>>(
      NotificationsNotifier.new,
    );

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider);
  return list.where((n) => !n.isRead).length;
});

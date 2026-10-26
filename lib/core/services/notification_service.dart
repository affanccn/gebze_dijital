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
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? time,
    IconData? icon,
    Color? color,
    NotificationCategory? category,
    String? actionType,
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

  /// Bildirimi API üzerinde okundu olarak işaretler (API PATCH).
  Future<bool> patchNotificationAsRead(String notificationId) async {
    try {
      final uri = Uri.parse('$kNotificationApiBaseUrl/$notificationId/read');
      final response = await _client.patch(
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
      ).timeout(const Duration(seconds: 4));

      debugPrint('[API PATCH] Bildirim $notificationId okundu: ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('[API PATCH] Bildirim $notificationId güncelleme isteği yapıldı: $e');
      return false;
    }
  }

  /// Tüm bildirimleri API üzerinde okundu olarak işaretler (API PATCH).
  Future<bool> patchAllNotificationsAsRead(List<String> notificationIds) async {
    try {
      final uri = Uri.parse('$kNotificationApiBaseUrl/read-all');
      final response = await _client.patch(
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
      ).timeout(const Duration(seconds: 4));

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
          actionType: 'food',
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
          actionType: 'pati',
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
          .listen((snapshot) async {
        await _handleFirestoreSnapshot(snapshot);
      }, onError: (e) {
        debugPrint('[NotificationsNotifier] Firestore dinleme hatası: $e');
      });
    } catch (e) {
      debugPrint('[NotificationsNotifier] Firestore başlatılamadı: $e');
    }
  }

  Future<void> _handleFirestoreSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList(_kReadNotificationsKey) ?? [];

      final List<AppNotification> firestoreItems = [];

      for (final doc in snapshot.docs) {
        final d = doc.data();
        final id = doc.id;
        final title = (d['title'] as String?)?.trim() ?? 'Gebze Belediyesi Duyurusu';
        final message = (d['message'] as String?)?.trim() ?? '';
        final topic = d['topic'] as String?;
        final category = d['category'] as String?;
        final createdAt = d['createdAt'];
        final createdAtText = d['createdAtText'] as String?;

        final isRead = readIds.contains(id);

        firestoreItems.add(AppNotification(
          id: id,
          title: title,
          message: message,
          time: _formatNotificationTime(createdAt, createdAtText),
          icon: _mapIcon(topic, category),
          color: _mapColor(topic, category),
          category: _mapCategory(category, topic),
          actionType: _mapActionType(topic, category),
          isRead: isRead,
        ));
      }

      // Başlangıç mock listesindeki çakışmayanları koru
      final existingInitial = _initialNotifications.where(
        (n) => !firestoreItems.any((fn) => fn.id == n.id),
      ).map((n) {
        if (readIds.contains(n.id)) return n.copyWith(isRead: true);
        return n;
      }).toList();

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
                final newNotif = AppNotification(
                  id: id,
                  title: (d['title'] as String?)?.trim() ?? 'Gebze Belediyesi Duyurusu',
                  message: (d['message'] as String?)?.trim() ?? '',
                  time: 'Az önce',
                  icon: _mapIcon(topic, category),
                  color: _mapColor(topic, category),
                  category: _mapCategory(category, topic),
                  actionType: _mapActionType(topic, category),
                  isRead: false,
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

  IconData _mapIcon(String? topic, String? category) {
    if (topic == 'emergency' || category == 'emergency') {
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

  Color _mapColor(String? topic, String? category) {
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
    return const Color(0xFF0A2A66);
  }

  NotificationCategory _mapCategory(String? category, String? topic) {
    if (category == 'outages' || topic == 'outages') {
      return NotificationCategory.outages;
    }
    if (category == 'services') {
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

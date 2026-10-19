import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef TopicHandler = Future<void> Function(String topic);

class PushService {
  static const String prefPrefix = 'gebze_notif_pref_';

  static const List<String> supportedTopics = [
    'news',
    'outages',
    'emergency',
    'sozSende',
  ];

  /// Topic ve FCM push desteği olan platformlar (Android / iOS)
  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Test amaçlı topic abone handler'ı enjeksiyonu
  @visibleForTesting
  static TopicHandler? topicSubscriber;

  /// Test amaçlı topic abonelikten çıkma handler'ı enjeksiyonu
  @visibleForTesting
  static TopicHandler? topicUnsubscriber;

  /// FCM topic abone olma fonksiyonu (test edilebilir ve platform korumalı)
  static Future<void> subscribeToTopic(String topic) async {
    if (topicSubscriber != null) {
      await topicSubscriber!(topic);
      return;
    }
    if (!isSupportedPlatform) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      debugPrint('[PushService] Abone olundu: topic=$topic');
    } catch (e) {
      debugPrint('[PushService] Abone olma hatası ($topic): $e');
    }
  }

  /// FCM topic abonelikten çıkma fonksiyonu
  static Future<void> unsubscribeFromTopic(String topic) async {
    if (topicUnsubscriber != null) {
      await topicUnsubscriber!(topic);
      return;
    }
    if (!isSupportedPlatform) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      debugPrint('[PushService] Abonelikten çıkıldı: topic=$topic');
    } catch (e) {
      debugPrint('[PushService] Abonelikten çıkma hatası ($topic): $e');
    }
  }

  /// Tek bir tercihi senkronize eder (SharedPreferences ve FCM topics)
  static Future<void> syncPreference(String key, bool enabled) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('$prefPrefix$key', enabled);
    } catch (e) {
      debugPrint('[PushService] SharedPreferences yazma hatası: $e');
    }

    if (!isSupportedPlatform && topicSubscriber == null && topicUnsubscriber == null) return;
    if (key == 'push') {
      if (!enabled) {
        // Tüm topic aboneliklerinden çık
        for (final topic in supportedTopics) {
          await unsubscribeFromTopic(topic);
        }
      } else {
        // Master açıldı: açık olan tüm topiclere yeniden abone ol
        for (final topic in supportedTopics) {
          final isTopicAllowed = await getPreference(topic, defaultValue: true);
          if (isTopicAllowed) {
            await subscribeToTopic(topic);
          } else {
            await unsubscribeFromTopic(topic);
          }
        }
      }
      return;
    }

    // Alt topic ayarı değiştiğinde:
    if (supportedTopics.contains(key)) {
      final isMasterPush = await getPreference('push', defaultValue: true);
      if (!isMasterPush) {
        // Master kapalıysa hiçbir topic'e abone olunmaz
        await unsubscribeFromTopic(key);
      } else {
        if (enabled) {
          await subscribeToTopic(key);
        } else {
          await unsubscribeFromTopic(key);
        }
      }
    }
  }

  /// Tüm bildirim tercihlerini toplu olarak senkronize eder
  static Future<void> syncAllPreferences(Map<String, bool> prefs) async {
    try {
      final sp = await SharedPreferences.getInstance();
      for (final entry in prefs.entries) {
        await sp.setBool('$prefPrefix${entry.key}', entry.value);
      }
    } catch (e) {
      debugPrint('[PushService] SharedPreferences toplu yazma hatası: $e');
    }

    final isMasterPush = prefs['push'] ?? true;
    for (final topic in supportedTopics) {
      final isEnabled = prefs[topic] ?? true;
      if (isMasterPush && isEnabled) {
        await subscribeToTopic(topic);
      } else {
        await unsubscribeFromTopic(topic);
      }
    }
  }

  /// Yerel tercihi oku
  static Future<bool> getPreference(String key, {bool defaultValue = true}) async {
    try {
      final sp = await SharedPreferences.getInstance();
      return sp.getBool('$prefPrefix$key') ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  /// Bildirimin cihaza düşmesine izin veriliyor mu kontrolü (Gatekeeper)
  static Future<bool> isNotificationAllowed({String? type, String? category}) async {
    final isMasterPush = await getPreference('push', defaultValue: true);
    if (!isMasterPush) {
      debugPrint('[PushService] Master bildirim kapalı, bildirim engellendi.');
      return false;
    }

    final targetKey = (type ?? category ?? '').trim();
    if (targetKey.isNotEmpty && supportedTopics.contains(targetKey)) {
      final isCategoryAllowed = await getPreference(targetKey, defaultValue: true);
      if (!isCategoryAllowed) {
        debugPrint('[PushService] $targetKey bildirimi kapalı, bildirim engellendi.');
        return false;
      }
    }

    return true;
  }

  /// Push servisini başlatır
  static Future<void> init({required void Function() onNewsOpened}) async {
    if (!isSupportedPlatform) return;

    try {
      final m = FirebaseMessaging.instance;
      await m.requestPermission();

      // Kayıtlı tercihlere göre topic aboneliklerini başlat
      final isMasterPush = await getPreference('push', defaultValue: true);
      for (final topic in supportedTopics) {
        final allowed = await getPreference(topic, defaultValue: true);
        if (isMasterPush && allowed) {
          await subscribeToTopic(topic);
        } else {
          await unsubscribeFromTopic(topic);
        }
      }

      // Ön planda bildirim geldiğinde gatekeeper kontrolü
      FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
        final type = msg.data['type'] as String?;
        final category = msg.data['category'] as String?;
        final allowed = await isNotificationAllowed(type: type, category: category);
        if (!allowed) {
          debugPrint('[PushService] Ön plan bildirimi engellendi (kullanıcı tercihi kapalı): $type / $category');
          return;
        }
        debugPrint('[PushService] Ön plan bildirimi kabul edildi: ${msg.notification?.title}');
      });

      // Uygulama kapalıyken bildirime tıklandıysa
      final initial = await m.getInitialMessage();
      if (initial != null) {
        final type = initial.data['type'] as String?;
        if (await isNotificationAllowed(type: type)) {
          if (type == 'news') onNewsOpened();
        }
      }

      // Arka plandayken bildirime tıklandıysa
      FirebaseMessaging.onMessageOpenedApp.listen((msg) async {
        final type = msg.data['type'] as String?;
        if (await isNotificationAllowed(type: type)) {
          if (type == 'news') onNewsOpened();
        }
      });
    } catch (e) {
      // Push hatası uygulamanın açılmasını engellememeli.
      debugPrint('PushService hatası: $e');
    }
  }
}

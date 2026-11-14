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

  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @visibleForTesting
  static TopicHandler? topicSubscriber;

  @visibleForTesting
  static TopicHandler? topicUnsubscriber;
  static final Set<String> _subscribedTopics = {};

  static Future<void> subscribeToTopic(String topic) async {
    if (topicSubscriber != null) {
      await topicSubscriber!(topic);
      return;
    }
    if (_subscribedTopics.contains(topic)) return;
    _subscribedTopics.add(topic);
    if (!isSupportedPlatform) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      debugPrint('[PushService] Abone olundu: topic=$topic');
    } catch (e) {
      _subscribedTopics.remove(topic);
      debugPrint('[PushService] Abone olma hatası ($topic): $e');
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    if (topicUnsubscriber != null) {
      await topicUnsubscriber!(topic);
      return;
    }
    _subscribedTopics.remove(topic);
    if (!isSupportedPlatform) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      debugPrint('[PushService] Abonelikten çıkıldı: topic=$topic');
    } catch (e) {
      debugPrint('[PushService] Abonelikten çıkma hatası ($topic): $e');
    }
  }

  static Future<void> syncPreference(String key, bool enabled) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('$prefPrefix$key', enabled);
    } catch (e) {
      debugPrint('[PushService] SharedPreferences yazma hatası: $e');
    }

    if (!isSupportedPlatform &&
        topicSubscriber == null &&
        topicUnsubscriber == null) {
      return;
    }
    if (key == 'push') {
      if (!enabled) {
        for (final topic in supportedTopics) {
          await unsubscribeFromTopic(topic);
        }
      } else {
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

    if (supportedTopics.contains(key)) {
      final isMasterPush = await getPreference('push', defaultValue: true);
      if (!isMasterPush) {
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

  static Future<bool> getPreference(
    String key, {
    bool defaultValue = true,
  }) async {
    try {
      final sp = await SharedPreferences.getInstance();
      return sp.getBool('$prefPrefix$key') ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  static Future<bool> isNotificationAllowed({
    String? type,
    String? category,
  }) async {
    final isMasterPush = await getPreference('push', defaultValue: true);
    if (!isMasterPush) {
      debugPrint('[PushService] Master bildirim kapalı, bildirim engellendi.');
      return false;
    }

    final targetKey = (type ?? category ?? '').trim();
    if (targetKey.isNotEmpty && supportedTopics.contains(targetKey)) {
      final isCategoryAllowed = await getPreference(
        targetKey,
        defaultValue: true,
      );
      if (!isCategoryAllowed) {
        debugPrint(
          '[PushService] $targetKey bildirimi kapalı, bildirim engellendi.',
        );
        return false;
      }
    }

    return true;
  }

  static Future<void> init({required void Function() onNewsOpened}) async {
    if (!isSupportedPlatform) return;

    try {
      final m = FirebaseMessaging.instance;
      await m.requestPermission();

      final isMasterPush = await getPreference('push', defaultValue: true);
      for (final topic in supportedTopics) {
        final allowed = await getPreference(topic, defaultValue: true);
        if (isMasterPush && allowed) {
          await subscribeToTopic(topic);
        } else {
          await unsubscribeFromTopic(topic);
        }
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
        final type = msg.data['type'] as String?;
        final category = msg.data['category'] as String?;
        final allowed = await isNotificationAllowed(
          type: type,
          category: category,
        );
        if (!allowed) {
          debugPrint(
            '[PushService] Ön plan bildirimi engellendi (kullanıcı tercihi kapalı): $type / $category',
          );
          return;
        }
        debugPrint(
          '[PushService] Ön plan bildirimi kabul edildi: ${msg.notification?.title}',
        );
      });

      final initial = await m.getInitialMessage();
      if (initial != null) {
        final type = initial.data['type'] as String?;
        if (await isNotificationAllowed(type: type)) {
          if (type == 'news') onNewsOpened();
        }
      }

      FirebaseMessaging.onMessageOpenedApp.listen((msg) async {
        final type = msg.data['type'] as String?;
        if (await isNotificationAllowed(type: type)) {
          if (type == 'news') onNewsOpened();
        }
      });
    } catch (e) {
      debugPrint('PushService hatası: $e');
    }
  }
}

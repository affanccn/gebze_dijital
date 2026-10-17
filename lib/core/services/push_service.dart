import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushService {
  static Future<void> init({required void Function() onNewsOpened}) async {
    // Topic aboneliği web'de desteklenmiyor; sadece Android/iOS'ta çalışır.
    if (kIsWeb) return;

    try {
      final m = FirebaseMessaging.instance;
      await m.requestPermission();
      await m.subscribeToTopic('news');

      // uygulama kapalıyken bildirime tıklandıysa
      final initial = await m.getInitialMessage();
      if (initial != null && initial.data['type'] == 'news') onNewsOpened();

      // arka plandayken bildirime tıklandıysa
      FirebaseMessaging.onMessageOpenedApp.listen((msg) {
        if (msg.data['type'] == 'news') onNewsOpened();
      });
    } catch (e) {
      // Push hatası uygulamanın açılmasını engellememeli.
      debugPrint('PushService hatası: $e');
    }
  }
}

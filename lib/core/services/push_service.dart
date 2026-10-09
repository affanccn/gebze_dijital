import 'package:firebase_messaging/firebase_messaging.dart';

class PushService {
  static Future<void> init({required void Function() onNewsOpened}) async {
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
  }
}
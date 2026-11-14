import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gebze_dijital/core/services/push_service.dart';
import 'package:gebze_dijital/features/profile/services/profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<String> subscribedTopics = [];
  final List<String> unsubscribedTopics = [];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    subscribedTopics.clear();
    unsubscribedTopics.clear();

    PushService.topicSubscriber = (topic) async {
      subscribedTopics.add(topic);
    };
    PushService.topicUnsubscriber = (topic) async {
      unsubscribedTopics.add(topic);
    };
  });

  tearDown(() {
    PushService.topicSubscriber = null;
    PushService.topicUnsubscriber = null;
  });

  group('PushService Bildirim Tercihleri & Cihaz Teslimat Testleri', () {
    test('Varsayılan durumda tüm bildirim türlerine izin verilir', () async {
      expect(await PushService.isNotificationAllowed(), isTrue);
      expect(await PushService.isNotificationAllowed(type: 'news'), isTrue);
      expect(await PushService.isNotificationAllowed(type: 'outages'), isTrue);
      expect(
        await PushService.isNotificationAllowed(type: 'emergency'),
        isTrue,
      );
      expect(await PushService.isNotificationAllowed(type: 'sozSende'), isTrue);
    });

    test(
      'Master "push" toggle kapatıldığında tüm topic aboneliklerinden çıkılır',
      () async {
        await PushService.syncPreference('push', false);

        expect(await PushService.getPreference('push'), isFalse);
        expect(
          unsubscribedTopics,
          containsAll(['news', 'outages', 'emergency', 'sozSende']),
        );

        expect(await PushService.isNotificationAllowed(type: 'news'), isFalse);
        expect(
          await PushService.isNotificationAllowed(type: 'outages'),
          isFalse,
        );
        expect(
          await PushService.isNotificationAllowed(type: 'emergency'),
          isFalse,
        );
        expect(
          await PushService.isNotificationAllowed(type: 'sozSende'),
          isFalse,
        );
        expect(await PushService.isNotificationAllowed(), isFalse);
      },
    );

    test('Master "push" toggle tekrar açıldığında açık olan topiclere yeniden abone olunur', () async {
      await PushService.syncPreference('outages', false);
      await PushService.syncPreference('push', false);

      subscribedTopics.clear();
      unsubscribedTopics.clear();

      await PushService.syncPreference('push', true);

      expect(await PushService.getPreference('push'), isTrue);
      expect(subscribedTopics, contains('news'));
      expect(subscribedTopics, contains('emergency'));
      expect(subscribedTopics, contains('sozSende'));
      expect(subscribedTopics, isNot(contains('outages')));
      expect(unsubscribedTopics, contains('outages'));
    });

    test('Kesintiler (outages) toggle kapatıldığında cihaza kesinti bildirimi düşmez', () async {
      await PushService.syncPreference('outages', false);

      expect(await PushService.getPreference('outages'), isFalse);
      expect(unsubscribedTopics, contains('outages'));

      expect(await PushService.isNotificationAllowed(type: 'outages'), isFalse);
      expect(
        await PushService.isNotificationAllowed(category: 'outages'),
        isFalse,
      );

      expect(
        await PushService.isNotificationAllowed(type: 'emergency'),
        isTrue,
      );
      expect(await PushService.isNotificationAllowed(type: 'news'), isTrue);
    });

    test('Acil durum (emergency) toggle kapatıldığında cihaza afet/acil durum bildirimi düşmez', () async {
      await PushService.syncPreference('emergency', false);

      expect(await PushService.getPreference('emergency'), isFalse);
      expect(unsubscribedTopics, contains('emergency'));

      expect(
        await PushService.isNotificationAllowed(type: 'emergency'),
        isFalse,
      );
      expect(await PushService.isNotificationAllowed(type: 'news'), isTrue);
    });

    test(
      'Söz Sende (sozSende) anket toggle kapatıldığında anket bildirimi düşmez',
      () async {
        await PushService.syncPreference('sozSende', false);

        expect(await PushService.getPreference('sozSende'), isFalse);
        expect(unsubscribedTopics, contains('sozSende'));

        expect(
          await PushService.isNotificationAllowed(type: 'sozSende'),
          isFalse,
        );
        expect(
          await PushService.isNotificationAllowed(type: 'outages'),
          isTrue,
        );
      },
    );

    test('syncAllPreferences toplu bildirim tercihlerini uygular ve topicleri eşitler', () async {
      final prefs = {
        'push': true,
        'sms': true,
        'outages': true,
        'emergency': false,
        'news': true,
        'sozSende': false,
      };

      await PushService.syncAllPreferences(prefs);

      expect(await PushService.getPreference('push'), isTrue);
      expect(await PushService.getPreference('sms'), isTrue);
      expect(await PushService.getPreference('outages'), isTrue);
      expect(await PushService.getPreference('emergency'), isFalse);
      expect(await PushService.getPreference('sozSende'), isFalse);

      expect(subscribedTopics, contains('news'));
      expect(subscribedTopics, contains('outages'));
      expect(unsubscribedTopics, contains('emergency'));
      expect(unsubscribedTopics, contains('sozSende'));

      expect(await PushService.isNotificationAllowed(type: 'outages'), isTrue);
      expect(
        await PushService.isNotificationAllowed(type: 'emergency'),
        isFalse,
      );
      expect(
        await PushService.isNotificationAllowed(type: 'sozSende'),
        isFalse,
      );
    });

    test('ProfileService updateNotificationPreference PushService senkronizasyonunu tetikler', () async {
      final service = ProfileService();
      await service.updateNotificationPreference('outages', false);

      expect(await PushService.getPreference('outages'), isFalse);
      expect(unsubscribedTopics, contains('outages'));
      expect(await PushService.isNotificationAllowed(type: 'outages'), isFalse);
    });
  });
}

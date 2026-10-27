import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gebze_dijital/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationService & Provider Tests', () {
    test('NotificationService sends HTTP PATCH request to mark as read', () async {
      bool patchCalled = false;
      final mockClient = MockClient((request) async {
        if (request.method == 'PATCH' &&
            request.url.path.contains('/notifications/1/read')) {
          patchCalled = true;
          return http.Response('{"success": true}', 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = NotificationService(client: mockClient);
      final result = await service.patchNotificationAsRead('1');
      expect(result, true);
      expect(patchCalled, true);
    });

    test('unreadNotificationsCountProvider tracks unread and resets to 0 on markAllAsRead', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initially unread count is 5
      expect(container.read(unreadNotificationsCountProvider), 5);

      // Mark single item as read
      await container.read(notificationsProvider.notifier).markAsRead('1');
      expect(container.read(unreadNotificationsCountProvider), 4);

      // Mark all as read -> resets badge to 0
      await container.read(notificationsProvider.notifier).markAllAsRead();
      expect(container.read(unreadNotificationsCountProvider), 0);
    });
  });
}

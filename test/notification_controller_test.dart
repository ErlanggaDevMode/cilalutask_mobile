import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cilalutask_mobile/models/notification_item.dart';
import 'package:cilalutask_mobile/state/notification_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationController Unit Tests', () {
    test('Initializes with default notifications', () {
      final controller = NotificationController();
      addTearDown(() => controller.dispose());

      expect(controller.notifications.isNotEmpty, isTrue);
      expect(controller.unreadNotificationsCount, greaterThanOrEqualTo(0));
      expect(controller.activeInAppNotification, isNull);
    });

    test('pushNotification adds item and sets active banner', () {
      final controller = NotificationController();
      addTearDown(() => controller.dispose());

      final item = NotificationItem(
        id: 'notif-test-1',
        title: 'Pengumuman Penting',
        description: 'Server maintenance malam ini.',
        time: 'Baru saja',
        type: 'system',
        unread: true,
        timestamp: DateTime.now(),
      );

      controller.pushNotification('TEST-CO', item, showBanner: true);

      expect(controller.notifications.first.id, 'notif-test-1');
      expect(controller.activeInAppNotification?.id, 'notif-test-1');

      // Dismiss banner
      controller.dismissActiveNotification();
      expect(controller.activeInAppNotification, isNull);
    });

    test('markNotificationAsRead and markAllNotificationsAsRead update unread status', () {
      final controller = NotificationController();
      addTearDown(() => controller.dispose());

      final unreadCountBefore = controller.unreadNotificationsCount;
      expect(unreadCountBefore, greaterThan(0));

      // Mark all read
      controller.markAllNotificationsAsRead();
      expect(controller.unreadNotificationsCount, 0);
    });

    test('deleteNotification and clearAllNotifications update state', () async {
      final controller = NotificationController();
      addTearDown(() => controller.dispose());

      final firstId = controller.notifications.first.id;
      await controller.deleteNotification('TEST-CO', firstId);
      expect(controller.notifications.any((n) => n.id == firstId), isFalse);

      await controller.clearAllNotifications('TEST-CO');
      expect(controller.notifications.isEmpty, isTrue);
    });

    test('clear resets state completely', () {
      final controller = NotificationController();
      addTearDown(() => controller.dispose());

      controller.clear();
      expect(controller.notifications.isEmpty, isTrue);
      expect(controller.activeInAppNotification, isNull);
    });
  });
}

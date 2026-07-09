import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/notification_gateway.dart';
import 'package:lifeos/features/notifications/data/notification_repository_impl.dart';
import 'package:lifeos/features/notifications/domain/entities/app_notification.dart';

void main() {
  test('adding a notification fires the onAdded hook exactly once', () {
    final fired = <AppNotification>[];
    final repo = NotificationRepositoryImpl(onAdded: fired.add);

    final n = AppNotification(
      id: 'n1',
      tier: NotificationTier.critical,
      titleKey: 'aiMsg.pause.title',
      bodyKey: 'aiMsg.pause.msg',
      createdAt: DateTime(2026, 7, 4),
    );
    repo.add(n);

    expect(fired, [n]);
    expect(repo.all().single.id, 'n1');
  });

  test('marking all read does not re-fire the OS hook', () {
    var count = 0;
    final repo = NotificationRepositoryImpl(onAdded: (_) => count++);
    repo.add(AppNotification(
      id: 'n2',
      tier: NotificationTier.important,
      titleKey: 't',
      bodyKey: 'b',
      createdAt: DateTime(2026, 7, 4),
    ));
    repo.markAllRead();

    expect(count, 1);
  });

  test('the OS gateway is a safe no-op off-device (web/test)', () async {
    // In the test VM the gateway must never throw, regardless of platform.
    await notificationGateway.init();
    await notificationGateway.show(id: 1, title: 'hi', body: 'there');
  });
}

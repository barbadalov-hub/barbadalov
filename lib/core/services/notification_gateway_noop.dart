/// Web / no-OS-notification backend. Used on web (and any platform without
/// `dart:io`). Everything is a no-op — the in-app notification feed and the
/// unread-count badge are the whole story here.
class NotificationGateway {
  Future<void> init() async {}

  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {}

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {}

  Future<void> cancel(int id) async {}

  Future<void> cancelAll() async {}
}

/// Single shared instance, mirrored by the io backend.
final NotificationGateway notificationGateway = NotificationGateway();

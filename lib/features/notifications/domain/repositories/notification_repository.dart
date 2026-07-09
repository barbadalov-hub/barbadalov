import 'package:lifeos/features/notifications/domain/entities/app_notification.dart';

/// Store of generated notifications. Populated by the [NotificationEventHandler]
/// reacting to the event stream; read by the notifications UI and the Today
/// screen's unread badge.
abstract class NotificationRepository {
  void add(AppNotification notification);
  void markAllRead();

  /// Removes a single notification (swipe-to-dismiss).
  void remove(String id);

  /// Removes every notification (clear all).
  void clear();

  List<AppNotification> all();
  Stream<List<AppNotification>> watch();
}

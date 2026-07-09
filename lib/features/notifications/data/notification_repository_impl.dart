import 'dart:async';

import 'package:lifeos/features/notifications/domain/entities/app_notification.dart';
import 'package:lifeos/features/notifications/domain/repositories/notification_repository.dart';

/// In-memory notification store (Phase 6). Newest first; capped so it never
/// grows unbounded in a long session.
class NotificationRepositoryImpl implements NotificationRepository {
  static const _maxItems = 100;

  /// Fired once for every freshly added notification. The provider layer uses
  /// this to mirror the notification to the OS (phones) — kept as a callback so
  /// this data class stays free of Flutter / localization dependencies.
  final void Function(AppNotification)? onAdded;

  NotificationRepositoryImpl({this.onAdded});

  final List<AppNotification> _items = [];
  final StreamController<List<AppNotification>> _controller =
      StreamController<List<AppNotification>>.broadcast();

  @override
  void add(AppNotification notification) {
    _items.insert(0, notification);
    if (_items.length > _maxItems) _items.removeLast();
    _emit();
    onAdded?.call(notification);
  }

  @override
  void markAllRead() {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].markRead();
    }
    _emit();
  }

  @override
  void remove(String id) {
    _items.removeWhere((n) => n.id == id);
    _emit();
  }

  @override
  void clear() {
    _items.clear();
    _emit();
  }

  @override
  List<AppNotification> all() => List.unmodifiable(_items);

  @override
  Stream<List<AppNotification>> watch() async* {
    yield all();
    yield* _controller.stream;
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(all());
  }

  Future<void> dispose() => _controller.close();
}

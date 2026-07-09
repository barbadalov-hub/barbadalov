import 'dart:async';

import 'package:lifeos/core/events/life_event.dart';

/// The nervous system of LifeOS. Every feature publishes [LifeEvent]s here;
/// the [LifeCoreEngine] is the single subscriber that orchestrates side effects.
///
/// It is a broadcast stream, so multiple listeners (engine, debug logger,
/// future analytics sink) can observe the same event flow without coupling.
class EventBus {
  final _controller = StreamController<LifeEvent>.broadcast();

  /// Observe the raw event flow.
  Stream<LifeEvent> get stream => _controller.stream;

  /// Publish an event. This is the *only* way state change enters the system:
  ///
  ///   User Action → Event Created → EventBus → LifeCoreEngine → Repositories
  ///   → Firebase → AI Engine (if needed) → Notifications
  void publish(LifeEvent event) {
    if (_controller.isClosed) return;
    _controller.add(event);
  }

  Future<void> dispose() => _controller.close();
}

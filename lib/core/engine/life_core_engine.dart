import 'dart:async';

import 'package:lifeos/core/events/event_bus.dart';
import 'package:lifeos/core/events/event_handler.dart';
import 'package:lifeos/core/events/life_event.dart';

/// LIFEOS CORE ENGINE.
///
/// The single orchestrator of the system. It subscribes to the [EventBus] and,
/// for every [LifeEvent], fans the event out to every registered [EventHandler]
/// that declares it can handle it. Handlers are how the engine "updates system
/// state, computes budget, analyses health, triggers AI and generates
/// notifications" — each concern is an isolated, independently testable handler.
///
///   EventBus → LifeCoreEngine → [handlers] → Repositories / AI / Notifications
///
/// The UI never talks to the engine directly and never contains business logic;
/// it emits events and observes repositories.
class LifeCoreEngine {
  LifeCoreEngine(this._eventBus, {List<EventHandler> handlers = const []})
      : _handlers = List.of(handlers);

  final EventBus _eventBus;
  final List<EventHandler> _handlers;
  StreamSubscription<LifeEvent>? _subscription;

  /// Register a handler after construction (used by feature bootstrap code).
  void register(EventHandler handler) => _handlers.add(handler);

  /// Begin processing the event flow. Idempotent.
  void start() {
    _subscription ??= _eventBus.stream.listen(_dispatch);
  }

  Future<void> _dispatch(LifeEvent event) async {
    for (final handler in _handlers) {
      if (!handler.canHandle(event)) continue;
      try {
        await handler.handle(event);
      } catch (error, stackTrace) {
        // One handler failing must never poison the pipeline or other handlers.
        _onHandlerError(handler, event, error, stackTrace);
      }
    }
  }

  void _onHandlerError(
    EventHandler handler,
    LifeEvent event,
    Object error,
    StackTrace stackTrace,
  ) {
    // Phase 1: log. Later this feeds a crash reporter + a dead-letter queue so
    // failed side effects can be retried.
    // ignore: avoid_print
    print('[LifeCoreEngine] handler "${handler.name}" failed on '
        '${event.type}: $error');
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}

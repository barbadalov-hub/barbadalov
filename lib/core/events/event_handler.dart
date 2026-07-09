import 'package:lifeos/core/events/life_event.dart';

/// A reaction to events, registered with the [LifeCoreEngine]. Each feature
/// contributes handlers (persist to the event log, recompute a budget, raise a
/// notification, kick off AI analysis) without knowing about any other feature.
///
/// Handlers must be side-effect-safe and must not throw: the engine isolates
/// failures so one misbehaving handler cannot break the event pipeline.
abstract class EventHandler {
  /// Human-readable name for logging.
  String get name;

  /// Whether this handler cares about [event].
  bool canHandle(LifeEvent event);

  /// Perform the reaction. Should be idempotent where possible.
  Future<void> handle(LifeEvent event);
}

import 'package:lifeos/core/events/life_event.dart';

/// Base for the four HealthOS metric events. Each carries a single numeric
/// [value] plus a [metric] tag so decoupled handlers (AI, notifications) can
/// react without importing HealthOS types.
abstract class HealthLoggedEvent extends LifeEvent {
  final num value;
  const HealthLoggedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required this.value,
  });

  String get metric;

  @override
  Map<String, dynamic> toPayload() => {'metric': metric, 'value': value};
}

class WaterLoggedEvent extends HealthLoggedEvent {
  const WaterLoggedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required super.value,
  });
  @override
  String get type => 'water_logged';
  @override
  String get metric => 'water_glasses';
}

class StepsUpdatedEvent extends HealthLoggedEvent {
  const StepsUpdatedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required super.value,
  });
  @override
  String get type => 'steps_updated';
  @override
  String get metric => 'steps';
}

class SleepLoggedEvent extends HealthLoggedEvent {
  const SleepLoggedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required super.value,
  });
  @override
  String get type => 'sleep_logged';
  @override
  String get metric => 'sleep_hours';
}

class WeightLoggedEvent extends HealthLoggedEvent {
  const WeightLoggedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required super.value,
  });
  @override
  String get type => 'weight_logged';
  @override
  String get metric => 'weight_kg';
}

class StressLoggedEvent extends HealthLoggedEvent {
  const StressLoggedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required super.value,
  });
  @override
  String get type => 'stress_logged';
  @override
  String get metric => 'stress';
}

class HeartRateLoggedEvent extends HealthLoggedEvent {
  const HeartRateLoggedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required super.value,
  });
  @override
  String get type => 'heart_rate_updated';
  @override
  String get metric => 'heart_rate';
}

/// A workout from the exercise catalog was completed.
class WorkoutCompletedEvent extends LifeEvent {
  final String workoutId;

  const WorkoutCompletedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required this.workoutId,
  });

  @override
  String get type => 'workout_completed';

  @override
  Map<String, dynamic> toPayload() => {'workoutId': workoutId};
}

/// Headphones module (§14): carries the day's running total plus the increment
/// so handlers can detect the moment a threshold is crossed.
class ListeningLoggedEvent extends LifeEvent {
  final int totalMinutes;
  final int addedMinutes;

  const ListeningLoggedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required this.totalMinutes,
    required this.addedMinutes,
  });

  @override
  String get type => 'listening_logged';

  @override
  Map<String, dynamic> toPayload() => {
        'totalMinutes': totalMinutes,
        'addedMinutes': addedMinutes,
      };
}

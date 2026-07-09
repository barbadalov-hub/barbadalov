import 'package:lifeos/core/events/event_bus.dart';
import 'package:lifeos/core/events/life_event.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/id_service.dart';
import 'package:lifeos/features/health/domain/entities/health_day.dart';
import 'package:lifeos/features/health/domain/events/health_events.dart';
import 'package:lifeos/features/health/domain/repositories/health_repository.dart';

/// HealthOS write use cases. Each mutates today's [HealthDay] and publishes the
/// matching metric event through the [EventBus].
class LogHealth {
  final HealthRepository _repository;
  final EventBus _eventBus;
  final IdService _idService;
  final Clock _clock;

  /// Invoked after a weight log so the weight-history store can append a point
  /// (wired in the provider, same callback pattern as repository persistence).
  final void Function(DateTime date, double kg)? onWeightLogged;

  const LogHealth(
    this._repository,
    this._eventBus,
    this._idService,
    this._clock, {
    this.onWeightLogged,
  });

  void addWater({int glasses = 1, String userId = 'local'}) {
    final next = _repository.today().waterGlasses + glasses;
    _repository.update(_repository.today().copyWith(waterGlasses: next));
    _publish(WaterLoggedEvent(
      id: _idService.newId(),
      userId: userId,
      occurredAt: _clock.now(),
      value: next,
    ));
  }

  void setSteps(int steps, {String userId = 'local'}) {
    _repository.update(_repository.today().copyWith(steps: steps));
    _publish(StepsUpdatedEvent(
      id: _idService.newId(),
      userId: userId,
      occurredAt: _clock.now(),
      value: steps,
    ));
  }

  void logSleep(double hours, {String userId = 'local'}) {
    _repository.update(_repository.today().copyWith(sleepHours: hours));
    _publish(SleepLoggedEvent(
      id: _idService.newId(),
      userId: userId,
      occurredAt: _clock.now(),
      value: hours,
    ));
  }

  void logWeight(double kg, {String userId = 'local'}) {
    _repository.update(_repository.today().copyWith(weightKg: kg));
    onWeightLogged?.call(_clock.now(), kg);
    _publish(WeightLoggedEvent(
      id: _idService.newId(),
      userId: userId,
      occurredAt: _clock.now(),
      value: kg,
    ));
  }

  void logStress(int level, {String userId = 'local'}) {
    _repository.update(_repository.today().copyWith(stress: level));
    _publish(StressLoggedEvent(
      id: _idService.newId(),
      userId: userId,
      occurredAt: _clock.now(),
      value: level,
    ));
  }

  void setHeartRate(int bpm, {String userId = 'local'}) {
    _repository.update(_repository.today().copyWith(heartRate: bpm));
    _publish(HeartRateLoggedEvent(
      id: _idService.newId(),
      userId: userId,
      occurredAt: _clock.now(),
      value: bpm,
    ));
  }

  /// A catalog workout was finished — record it in the life history (and let
  /// the cloud/AI/notification handlers react like for any other event).
  void completeWorkout(String workoutId, {String userId = 'local'}) {
    _publish(WorkoutCompletedEvent(
      id: _idService.newId(),
      userId: userId,
      occurredAt: _clock.now(),
      workoutId: workoutId,
    ));
  }

  /// Headphones module (§14): accumulate listening time for today.
  void addListening(int minutes, {String userId = 'local'}) {
    final total = _repository.today().listeningMinutes + minutes;
    _repository.update(_repository.today().copyWith(listeningMinutes: total));
    _publish(ListeningLoggedEvent(
      id: _idService.newId(),
      userId: userId,
      occurredAt: _clock.now(),
      totalMinutes: total,
      addedMinutes: minutes,
    ));
  }

  void _publish(LifeEvent event) => _eventBus.publish(event);
}

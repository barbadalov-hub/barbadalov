import 'package:lifeos/features/health/domain/entities/health_day.dart';

/// Turns a [HealthDay] into a 0–100 health score — the average of progress
/// toward the water, steps and sleep goals (each capped at 100%). Feeds the
/// health pillar of the Life Score.
class HealthScoreService {
  const HealthScoreService();

  /// Minutes of training that count as a full day's worth. Thirty is the
  /// familiar daily target behind the usual 150-a-week advice.
  static const trainingGoalMinutes = 30;

  /// How much a full day of training can lift the score.
  static const trainingBonus = 15;

  /// [activeMinutes] is training logged today.
  ///
  /// It is a **bonus on top**, not a fourth equal part. Making it a quarter of
  /// the average would have dropped the score of everyone who does not log
  /// workouts — the same day, the same habits, a worse number, purely because
  /// the app grew a feature. Training can raise this score and can never
  /// lower it.
  int scoreFor(HealthDay day, {int activeMinutes = 0}) {
    final water = _pct(day.waterGlasses, HealthGoals.waterGlasses);
    final steps = _pct(day.steps, HealthGoals.steps);
    final sleep = _pct(day.sleepHours, HealthGoals.sleepHours);
    final base = (water + steps + sleep) / 3 * 100;

    final training = _pct(activeMinutes, trainingGoalMinutes) * trainingBonus;
    return (base + training).round().clamp(0, 100).toInt();
  }

  double _pct(num value, num goal) {
    if (goal <= 0) return 0;
    final r = value / goal;
    return r > 1 ? 1 : r;
  }
}

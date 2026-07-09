import 'package:lifeos/features/health/domain/entities/health_day.dart';

/// Turns a [HealthDay] into a 0–100 health score — the average of progress
/// toward the water, steps and sleep goals (each capped at 100%). Feeds the
/// health pillar of the Life Score.
class HealthScoreService {
  const HealthScoreService();

  int scoreFor(HealthDay day) {
    final water = _pct(day.waterGlasses, HealthGoals.waterGlasses);
    final steps = _pct(day.steps, HealthGoals.steps);
    final sleep = _pct(day.sleepHours, HealthGoals.sleepHours);
    return ((water + steps + sleep) / 3 * 100).round().clamp(0, 100).toInt();
  }

  double _pct(num value, num goal) {
    if (goal <= 0) return 0;
    final r = value / goal;
    return r > 1 ? 1 : r;
  }
}

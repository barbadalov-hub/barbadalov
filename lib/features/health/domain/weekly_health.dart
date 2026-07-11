import 'package:equatable/equatable.dart';
import 'package:lifeos/features/health/domain/entities/health_day.dart';

/// A 7-day rollup of health metrics: averages and how many days hit each goal.
class WeeklyHealthSummary extends Equatable {
  final int daysLogged;
  final int avgSteps;
  final double avgWater;
  final double avgSleep;
  final int daysStepGoal;
  final int daysWaterGoal;
  final int daysSleepGoal;

  const WeeklyHealthSummary({
    required this.daysLogged,
    required this.avgSteps,
    required this.avgWater,
    required this.avgSleep,
    required this.daysStepGoal,
    required this.daysWaterGoal,
    required this.daysSleepGoal,
  });

  static const empty = WeeklyHealthSummary(
    daysLogged: 0,
    avgSteps: 0,
    avgWater: 0,
    avgSleep: 0,
    daysStepGoal: 0,
    daysWaterGoal: 0,
    daysSleepGoal: 0,
  );

  bool get hasData => daysLogged > 0;

  @override
  List<Object?> get props => [
        daysLogged, avgSteps, avgWater, avgSleep, //
        daysStepGoal, daysWaterGoal, daysSleepGoal,
      ];
}

/// Aggregates the trailing 7 days (including today) into a [WeeklyHealthSummary].
/// Pure & deterministic. Multiple entries for the same date are de-duplicated,
/// last one winning, so combining "today" with archived history is safe.
class HealthWeek {
  const HealthWeek._();

  static WeeklyHealthSummary summarize(List<HealthDay> days, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));

    // De-dup by calendar day within the window.
    final inWeek = <DateTime, HealthDay>{};
    for (final d in days) {
      final key = DateTime(d.date.year, d.date.month, d.date.day);
      if (key.isBefore(start) || key.isAfter(today)) continue;
      inWeek[key] = d;
    }
    if (inWeek.isEmpty) return WeeklyHealthSummary.empty;

    final wk = inWeek.values;
    final n = wk.length;
    final steps = wk.fold<int>(0, (s, d) => s + d.steps);
    final water = wk.fold<int>(0, (s, d) => s + d.waterGlasses);
    final sleep = wk.fold<double>(0, (s, d) => s + d.sleepHours);

    return WeeklyHealthSummary(
      daysLogged: n,
      avgSteps: (steps / n).round(),
      avgWater: water / n,
      avgSleep: sleep / n,
      daysStepGoal: wk.where((d) => d.steps >= HealthGoals.steps).length,
      daysWaterGoal:
          wk.where((d) => d.waterGlasses >= HealthGoals.waterGlasses).length,
      daysSleepGoal:
          wk.where((d) => d.sleepHours >= HealthGoals.sleepHours).length,
    );
  }
}

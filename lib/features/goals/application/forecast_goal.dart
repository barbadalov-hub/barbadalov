import 'package:lifeos/features/goals/domain/entities/goal.dart';
import 'package:lifeos/shared/models/money.dart';

class GoalForecast {
  /// Months until the goal is funded at the current savings rate; null when it
  /// can't be projected (nothing being saved).
  final int? monthsRemaining;
  final DateTime? projectedDate;
  final bool onTrackForTargetDate;
  final bool complete;

  const GoalForecast({
    this.monthsRemaining,
    this.projectedDate,
    this.onTrackForTargetDate = true,
    this.complete = false,
  });
}

/// Projects when a goal will be reached given the current monthly net savings
/// (a MoneyOS number), and whether that beats the goal's target date.
class ForecastGoal {
  const ForecastGoal();

  GoalForecast call(
    Goal goal, {
    required Money monthlyNet,
    required DateTime now,
  }) {
    if (goal.isComplete) return const GoalForecast(complete: true);
    if (monthlyNet.minorUnits <= 0) {
      return const GoalForecast(onTrackForTargetDate: false);
    }

    final months = (goal.remaining.minorUnits / monthlyNet.minorUnits).ceil();
    final projected = DateTime(now.year, now.month + months, now.day);
    final onTrack =
        goal.targetDate == null ? true : !projected.isAfter(goal.targetDate!);

    return GoalForecast(
      monthsRemaining: months,
      projectedDate: projected,
      onTrackForTargetDate: onTrack,
    );
  }
}

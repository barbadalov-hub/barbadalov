import 'package:lifeos/features/goals/domain/entities/goal.dart';
import 'package:lifeos/shared/models/money.dart';

class GoalForecast {
  /// Months until the goal is funded at the current savings rate; null when it
  /// can't be projected (nothing being saved).
  final int? monthsRemaining;
  final DateTime? projectedDate;
  final bool onTrackForTargetDate;
  final bool complete;

  /// The monthly contribution needed to reach the goal by its target date;
  /// null when there is no target date or it has already passed.
  final Money? requiredMonthly;

  const GoalForecast({
    this.monthsRemaining,
    this.projectedDate,
    this.onTrackForTargetDate = true,
    this.complete = false,
    this.requiredMonthly,
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

    final required = _requiredMonthly(goal, now);

    if (monthlyNet.minorUnits <= 0) {
      return GoalForecast(
        onTrackForTargetDate: false,
        requiredMonthly: required,
      );
    }

    final months = (goal.remaining.minorUnits / monthlyNet.minorUnits).ceil();
    final projected = DateTime(now.year, now.month + months, now.day);
    final onTrack =
        goal.targetDate == null ? true : !projected.isAfter(goal.targetDate!);

    return GoalForecast(
      monthsRemaining: months,
      projectedDate: projected,
      onTrackForTargetDate: onTrack,
      requiredMonthly: required,
    );
  }

  /// Monthly contribution needed to fund [goal] by its target date. Null when
  /// there is no target date or the target month has already arrived/passed.
  Money? _requiredMonthly(Goal goal, DateTime now) {
    final target = goal.targetDate;
    if (target == null) return null;
    final monthsUntil =
        (target.year - now.year) * 12 + (target.month - now.month);
    if (monthsUntil <= 0) return null;
    final perMonth = (goal.remaining.minorUnits / monthsUntil).ceil();
    return Money(perMonth, currency: goal.remaining.currency);
  }
}

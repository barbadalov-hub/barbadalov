import 'package:equatable/equatable.dart';
import 'package:lifeos/shared/models/money.dart';

/// Where the month is heading if spending continues at the current pace.
class MonthEndProjection extends Equatable {
  /// Expenses extrapolated linearly to the last day of the month.
  final Money projectedSpend;

  /// Spendable income (income − reserve) minus [projectedSpend]. Signed: a
  /// negative value means the month is on course to overspend by that much.
  final Money projectedLeftover;

  /// Average spend per elapsed day so far (minor units per day).
  final Money dailyPace;

  const MonthEndProjection({
    required this.projectedSpend,
    required this.projectedLeftover,
    required this.dailyPace,
  });

  /// True while the projected spend still fits inside spendable income.
  bool get onTrack => !projectedLeftover.isNegative;

  @override
  List<Object?> get props => [projectedSpend, projectedLeftover, dailyPace];
}

/// Use case: project month-end spending from the pace so far.
///
/// Pure computation (no I/O): extrapolate expenses-to-date linearly over the
/// elapsed share of the month, then measure the result against spendable income
/// (income − reserve). Makes the "at this rate you'll have X left" insight
/// trivial to unit-test.
class ProjectMonthEnd {
  const ProjectMonthEnd();

  MonthEndProjection call({
    required Money income,
    required Money expensesSoFar,
    required Money reserve,
    required int dayOfMonth,
    required int daysInMonth,
  }) {
    final currency = expensesSoFar.currency;
    // Guard against a zero/garbage calendar so we never divide by zero.
    final days = daysInMonth < 1 ? 1 : daysInMonth;
    final day = dayOfMonth.clamp(1, days);

    final dailyPace =
        Money(expensesSoFar.minorUnits ~/ day, currency: currency);
    final projectedSpend = Money(
      (expensesSoFar.minorUnits * days / day).round(),
      currency: currency,
    );
    final spendable = income - reserve;
    final projectedLeftover = spendable - projectedSpend;

    return MonthEndProjection(
      projectedSpend: projectedSpend,
      projectedLeftover: projectedLeftover,
      dailyPace: dailyPace,
    );
  }
}

import 'package:equatable/equatable.dart';
import 'package:lifeos/shared/models/money.dart';

/// The computed monthly money picture — the output of the ComputeBudget use
/// case and the source of the Today screen's headline "safe to spend today".
///
/// Reserve is automatically carved out of income (10–20% per the system rules)
/// *before* anything is considered spendable.
class Budget extends Equatable {
  /// All income recorded this month.
  final Money income;

  /// All expenses recorded this month.
  final Money expenses;

  /// Auto-reserve set aside from income (income * reserveRate).
  final Money reserve;

  /// Reserve share actually applied, in the sanctioned 0.10–0.20 band.
  final double reserveRate;

  /// income − reserve − expenses, floored at zero.
  final Money available;

  /// Even split of [available] across the remaining days of the month.
  final Money safeToSpendToday;

  /// Days left in the current month, including today.
  final int remainingDays;

  const Budget({
    required this.income,
    required this.expenses,
    required this.reserve,
    required this.reserveRate,
    required this.available,
    required this.safeToSpendToday,
    required this.remainingDays,
  });

  factory Budget.empty({String currency = 'USD'}) => Budget(
        income: Money.zero(currency: currency),
        expenses: Money.zero(currency: currency),
        reserve: Money.zero(currency: currency),
        reserveRate: 0,
        available: Money.zero(currency: currency),
        safeToSpendToday: Money.zero(currency: currency),
        remainingDays: 0,
      );

  /// Share of available budget already consumed (0.0–1.0+), for progress UI.
  double get spendProgress {
    final ceiling = available.minorUnits + expenses.minorUnits;
    if (ceiling <= 0) return 0;
    return expenses.minorUnits / ceiling;
  }

  bool get isOverspent => available.isZero && expenses > income - reserve;

  @override
  List<Object?> get props => [
        income,
        expenses,
        reserve,
        reserveRate,
        available,
        safeToSpendToday,
        remainingDays,
      ];
}

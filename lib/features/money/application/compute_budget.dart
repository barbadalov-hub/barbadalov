import 'package:lifeos/core/constants/app_constants.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/features/money/domain/entities/budget.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/shared/models/money.dart';

/// Use case: turn a month's transactions into a [Budget].
///
/// This is a *pure* computation (no I/O), which makes the core money rule —
/// "reserve 10–20% of income automatically, then spread what's left across the
/// remaining days" — trivial to unit test.
class ComputeBudget {
  final Clock _clock;
  const ComputeBudget(this._clock);

  Budget call(
    List<Transaction> monthTransactions, {
    double reserveRate = AppConstants.defaultReserveRate,
    String currency = AppConstants.defaultCurrency,
    DateTime? at,
  }) {
    final now = at ?? _clock.now();

    // Clamp the reserve rate into the sanctioned 10–20% band.
    // (`num.clamp` returns `num`, so coerce back to `double`.)
    final rate = reserveRate
        .clamp(AppConstants.minReserveRate, AppConstants.maxReserveRate)
        .toDouble();

    var incomeMinor = 0;
    var expenseMinor = 0;
    for (final t in monthTransactions) {
      if (t.isIncome) {
        incomeMinor += t.amount.minorUnits;
      } else {
        expenseMinor += t.amount.minorUnits;
      }
    }

    final income = Money(incomeMinor, currency: currency);
    final expenses = Money(expenseMinor, currency: currency);
    final reserve = Money((incomeMinor * rate).round(), currency: currency);
    final available = (income - reserve - expenses).clampToZero();

    final remainingDays = _remainingDaysInMonth(now);
    final safeToday = remainingDays > 0
        ? Money(available.minorUnits ~/ remainingDays, currency: currency)
        : available;

    return Budget(
      income: income,
      expenses: expenses,
      reserve: reserve,
      reserveRate: rate,
      available: available,
      safeToSpendToday: safeToday,
      remainingDays: remainingDays,
    );
  }

  /// Days left in [now]'s month, counting today.
  int _remainingDaysInMonth(DateTime now) {
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return lastDay - now.day + 1;
  }
}

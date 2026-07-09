import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/features/money/application/compute_budget.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/shared/models/money.dart';

class _FixedClock implements Clock {
  final DateTime _now;
  const _FixedClock(this._now);
  @override
  DateTime now() => _now;
}

Transaction _tx(int major, TransactionType type) => Transaction(
      id: 'id_$major$type',
      amount: Money.fromMajor(major),
      type: type,
      categoryId: type == TransactionType.income
          ? DefaultCategories.salary.id
          : DefaultCategories.food.id,
      date: DateTime(2025, 1, 1),
    );

void main() {
  group('ComputeBudget', () {
    // 1 Jan 2025 → January has 31 days → 31 days remaining including today.
    final compute = ComputeBudget(_FixedClock(DateTime(2025, 1, 1)));

    test('reserves 15% of income by default and derives available', () {
      final budget = compute([
        _tx(1000, TransactionType.income),
        _tx(100, TransactionType.expense),
      ]);

      expect(budget.income, Money.fromMajor(1000));
      expect(budget.expenses, Money.fromMajor(100));
      expect(budget.reserve, Money.fromMajor(150)); // 15%
      expect(budget.available, Money.fromMajor(750)); // 1000 - 150 - 100
      expect(budget.remainingDays, 31);
      // 75000 minor units spread across 31 days.
      expect(budget.safeToSpendToday.minorUnits, 75000 ~/ 31);
    });

    test('clamps the reserve rate into the 10–20% band', () {
      final budget = compute(
        [_tx(1000, TransactionType.income)],
        reserveRate: 0.9, // absurd → clamped to 0.20
      );
      expect(budget.reserveRate, 0.20);
      expect(budget.reserve, Money.fromMajor(200));
    });

    test('available never goes negative when overspending', () {
      final budget = compute([
        _tx(100, TransactionType.income),
        _tx(500, TransactionType.expense),
      ]);
      expect(budget.available, const Money.zero());
      expect(budget.isOverspent, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/money/application/month_comparison.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/shared/models/money.dart';

Transaction _exp(int major, DateTime date, {String cat = 'food'}) => Transaction(
      id: '${date.toIso8601String()}-$major-$cat',
      amount: Money.fromMajor(major),
      type: TransactionType.expense,
      categoryId: cat,
      date: date,
    );

void main() {
  test('compares only the same elapsed days on both sides', () {
    // Today is the 10th. Last month had spending both before and after the 10th.
    final now = DateTime(2026, 6, 10);
    final tx = [
      _exp(100, DateTime(2026, 6, 3)), // this month, counts
      _exp(50, DateTime(2026, 6, 9)), // this month, counts
      _exp(80, DateTime(2026, 5, 5)), // last month ≤10th, counts
      _exp(1000, DateTime(2026, 5, 25)), // last month AFTER the 10th, excluded
    ];
    final c = MonthComparison.compute(transactions: tx, now: now);
    expect(c.thisSpent, Money.fromMajor(150).minorUnits);
    expect(c.lastSpent, Money.fromMajor(80).minorUnits); // NOT 1080
    // 150 vs 80 → +87.5% → rounds to 88.
    expect(c.pctChange, 88);
    expect(c.delta, Money.fromMajor(70).minorUnits);
  });

  test('ignores income and future-dated entries', () {
    final now = DateTime(2026, 6, 10);
    final tx = [
      _exp(100, DateTime(2026, 6, 3)),
      Transaction(
        id: 'inc',
        amount: Money.fromMajor(500),
        type: TransactionType.income,
        categoryId: 'salary',
        date: DateTime(2026, 6, 4),
      ),
      _exp(999, DateTime(2026, 6, 20)), // future day-of-month, excluded
    ];
    final c = MonthComparison.compute(transactions: tx, now: now);
    expect(c.thisSpent, Money.fromMajor(100).minorUnits);
  });

  test('finds the category that moved the most', () {
    final now = DateTime(2026, 6, 15);
    final tx = [
      _exp(200, DateTime(2026, 6, 2), cat: 'food'),
      _exp(40, DateTime(2026, 5, 2), cat: 'food'), // food +160
      _exp(30, DateTime(2026, 6, 2), cat: 'fun'),
      _exp(50, DateTime(2026, 5, 2), cat: 'fun'), // fun −20
    ];
    final c = MonthComparison.compute(transactions: tx, now: now);
    expect(c.topMoverCategory, 'food');
    expect(c.topMoverDelta, Money.fromMajor(160).minorUnits);
  });

  test('pctChange is null when there was no spending last month', () {
    final now = DateTime(2026, 6, 10);
    final c = MonthComparison.compute(
        transactions: [_exp(100, DateTime(2026, 6, 3))], now: now);
    expect(c.hasLast, isFalse);
    expect(c.pctChange, isNull);
  });
}

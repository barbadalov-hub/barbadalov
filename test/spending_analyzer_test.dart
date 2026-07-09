import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/features/goals/domain/entities/goal.dart';
import 'package:lifeos/features/money/application/compute_budget.dart';
import 'package:lifeos/features/money/application/spending_analyzer.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/shared/models/money.dart';

class _FixedClock implements Clock {
  final DateTime _now;
  const _FixedClock(this._now);
  @override
  DateTime now() => _now;
}

Transaction _tx(int major, TransactionType type, Category cat, int day) =>
    Transaction(
      id: 'id_${cat.id}_$day-$major',
      amount: Money.fromMajor(major),
      type: type,
      categoryId: cat.id,
      date: DateTime(2026, 7, day),
    );

void main() {
  const analyzer = SpendingAnalyzer();
  // 10 July 2026 → 31-day month, 10 days passed, 21 left.
  final now = DateTime(2026, 7, 10);
  final compute = ComputeBudget(_FixedClock(now));

  test('overspending pace produces pace, projection, cut and goal insights',
      () {
    // Income 3100, reserve 15% (465) → spendable 2635, planned ≈ 85/day.
    // Spent 1500 in 10 days → 150/day → projected 1500+150*21=4650 ≫ 2635.
    final tx = [
      _tx(3100, TransactionType.income, DefaultCategories.salary, 1),
      _tx(900, TransactionType.expense, DefaultCategories.fun, 5),
      _tx(600, TransactionType.expense, DefaultCategories.food, 8),
    ];
    final insights = analyzer.analyze(
      budget: compute(tx, at: now),
      monthTransactions: tx,
      goals: [
        Goal(
          id: 'g',
          title: 'Car',
          emoji: '🚗',
          target: Money.fromMajor(5000),
          saved: Money.fromMajor(1000),
        ),
      ],
      now: now,
    );

    final keys = insights.map((i) => i.titleKey).toList();
    expect(keys, contains('smart.pace.title'));
    expect(keys, contains('smart.projection.title'));
    expect(keys, contains('smart.cut.title'));
    expect(keys, contains('smart.goal.title'));

    // The cut target must be the biggest discretionary category — fun (900).
    final cut = insights.firstWhere((i) => i.titleKey == 'smart.cut.title');
    expect(cut.params['catId'], 'cat.expense_fun');
    expect(cut.params['pct'], 60); // 900 of 1500
  });

  test('healthy pace produces a positive insight and no projection alarm', () {
    // Spent 400 in 10 days → 40/day, well under the ~85/day plan.
    final tx = [
      _tx(3100, TransactionType.income, DefaultCategories.salary, 1),
      _tx(400, TransactionType.expense, DefaultCategories.food, 6),
    ];
    final insights = analyzer.analyze(
      budget: compute(tx, at: now),
      monthTransactions: tx,
      goals: const [],
      now: now,
    );

    expect(insights.any((i) => i.titleKey == 'smart.paceOk.title'), isTrue);
    expect(
        insights.any((i) => i.titleKey == 'smart.projection.title'), isFalse);
    expect(insights.first.positive, isTrue);
  });

  test('adds allowance, savings-rate and top-category recommendations', () {
    // Income 3100, spent 400 (all food) in 10 days → healthy.
    final tx = [
      _tx(3100, TransactionType.income, DefaultCategories.salary, 1),
      _tx(400, TransactionType.expense, DefaultCategories.food, 6),
    ];
    final insights = analyzer.analyze(
      budget: compute(tx, at: now),
      monthTransactions: tx,
      goals: const [],
      now: now,
    );
    final keys = insights.map((i) => i.titleKey).toList();

    expect(keys.first, 'smart.allowance.title'); // most actionable, shown first
    expect(keys, contains('smart.savings.title'));
    final top = insights.firstWhere((i) => i.titleKey == 'smart.top.title');
    expect(top.params['catId'], 'cat.expense_food');
    expect(top.params['pct'], 100); // food is 100% of spend
  });

  test('flags high "wants" against the 50/30/20 rule', () {
    // 1200 on fun out of 3100 income = 39% > 30%.
    final tx = [
      _tx(3100, TransactionType.income, DefaultCategories.salary, 1),
      _tx(1200, TransactionType.expense, DefaultCategories.fun, 4),
    ];
    final insights = analyzer.analyze(
      budget: compute(tx, at: now),
      monthTransactions: tx,
      goals: const [],
      now: now,
    );
    final wants = insights.firstWhere((i) => i.titleKey == 'smart.wants.title');
    expect(wants.params['pct'], 39);
  });

  test('no income → analyzer stays silent', () {
    final insights = analyzer.analyze(
      budget: compute(const [], at: now),
      monthTransactions: const [],
      goals: const [],
      now: now,
    );
    expect(insights, isEmpty);
  });
}

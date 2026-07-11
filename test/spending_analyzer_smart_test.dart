import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/money/application/spending_analyzer.dart';
import 'package:lifeos/features/money/domain/entities/budget.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/shared/models/money.dart';

Budget _budget({
  required int income,
  required int reserve,
  required int expenses,
}) {
  final available = Money(income - reserve - expenses).clampToZero();
  return Budget(
    income: Money(income),
    expenses: Money(expenses),
    reserve: Money(reserve),
    reserveRate: 0.15,
    available: available,
    safeToSpendToday: const Money.zero(),
    remainingDays: 21,
  );
}

Transaction _exp(String cat, int minor) => Transaction(
      id: cat,
      amount: Money(minor),
      type: TransactionType.expense,
      categoryId: cat,
      date: DateTime(2026, 1, 5),
    );

void main() {
  const analyzer = SpendingAnalyzer();
  final now = DateTime(2026, 1, 10); // day 10 of a 31-day month

  Set<String> titles(List<FinanceInsight> xs) =>
      xs.map((i) => i.titleKey).toSet();

  test('no income yields no insights', () {
    final out = analyzer.analyze(
      budget: _budget(income: 0, reserve: 0, expenses: 0),
      monthTransactions: const [],
      goals: const [],
      now: now,
    );
    expect(out, isEmpty);
  });

  test('an overspending pace raises pace, projection, top and cut insights', () {
    final txns = [_exp('expense_food', 90000), _exp('expense_fun', 60000)];
    final out = analyzer.analyze(
      budget: _budget(income: 300000, reserve: 45000, expenses: 150000),
      monthTransactions: txns,
      goals: const [],
      now: now,
    );
    final t = titles(out);
    expect(t, contains('smart.allowance.title'));
    expect(t, contains('smart.pace.title')); // spending too fast
    expect(t, contains('smart.projection.title')); // will blow the budget
    expect(t, contains('smart.top.title')); // biggest bucket
    expect(t, contains('smart.cut.title')); // squeeze suggestion

    // Top category is the biggest expense bucket (food, 60% of spend).
    final top = out.firstWhere((i) => i.titleKey == 'smart.top.title');
    expect(top.params['catId'], 'cat.expense_food');
    expect(top.params['pct'], 60);
  });

  test('a calm pace praises the user and flags a healthy savings rate', () {
    final out = analyzer.analyze(
      budget: _budget(income: 300000, reserve: 45000, expenses: 20000),
      monthTransactions: [_exp('expense_food', 20000)],
      goals: const [],
      now: now,
    );
    final t = titles(out);
    expect(t, contains('smart.paceOk.title'));
    expect(t, contains('smart.savings.title'));
    expect(t, isNot(contains('smart.pace.title')));
    expect(t, isNot(contains('smart.projection.title')));
  });

  test('"wants" over 30% of income triggers a 50/30/20 nudge', () {
    // fun + other = 120000 of 300000 income = 40% > 30%.
    final out = analyzer.analyze(
      budget: _budget(income: 300000, reserve: 45000, expenses: 120000),
      monthTransactions: [_exp('expense_fun', 80000), _exp('expense_other', 40000)],
      goals: const [],
      now: now,
    );
    final wants = out.firstWhere((i) => i.titleKey == 'smart.wants.title');
    expect(wants.params['pct'], 40);
  });
}

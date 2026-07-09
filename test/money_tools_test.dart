import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/recurring_rule.dart';
import 'package:lifeos/features/money/presentation/providers/budget_limits_providers.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/features/money/presentation/providers/recurring_providers.dart';
import 'package:lifeos/features/reports/presentation/providers/report_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

class _FixedClock implements Clock {
  final DateTime t;
  const _FixedClock(this.t);
  @override
  DateTime now() => t;
}

void main() {
  ProviderContainer container(DateTime now, [InMemoryKeyValueStore? store]) {
    final c = ProviderContainer(overrides: [
      keyValueStoreProvider.overrideWithValue(store ?? InMemoryKeyValueStore()),
      clockProvider.overrideWithValue(_FixedClock(now)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('category limits', () {
    test('status flags over-limit and computes ratio', () {
      const s = CategoryLimitStatus(
        category: DefaultCategories.food,
        spent: Money(15000),
        limit: Money(10000),
      );
      expect(s.over, isTrue);
      expect(s.ratio, closeTo(1.5, 1e-9));
    });

    test('setting and clearing a limit persists', () {
      final store = InMemoryKeyValueStore();
      final c = container(DateTime(2026, 7, 15), store);
      c.read(categoryLimitsProvider.notifier)
          .setLimit(DefaultCategories.food.id, 50000);
      expect(c.read(categoryLimitsProvider)[DefaultCategories.food.id], 50000);

      // A fresh container over the same store rehydrates it.
      final c2 = container(DateTime(2026, 7, 15), store);
      expect(c2.read(categoryLimitsProvider)[DefaultCategories.food.id], 50000);

      // Zero clears it.
      c.read(categoryLimitsProvider.notifier)
          .setLimit(DefaultCategories.food.id, 0);
      expect(c.read(categoryLimitsProvider).containsKey(DefaultCategories.food.id),
          isFalse);
    });
  });

  group('recurring materializer', () {
    test('a due rule posts one transaction and is marked run', () async {
      final store = InMemoryKeyValueStore();
      final c = container(DateTime(2026, 7, 15, 9), store);

      final before = c.read(moneyLocalDataSourceProvider).all().length;
      c.read(recurringProvider.notifier).addNew(
            label: 'Salary',
            type: TransactionType.income,
            amountMinor: 300000,
            categoryId: DefaultCategories.salary.id,
            dayOfMonth: 10, // already passed on the 15th
          );

      c.read(recurringMaterializerProvider); // kick the microtask
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(c.read(moneyLocalDataSourceProvider).all().length, before + 1);
      expect(c.read(recurringProvider).single.lastRun, '2026-07');

      // Simulated restart in the same month must not double-post.
      final c2 = container(DateTime(2026, 7, 20, 9), store);
      final beforeRestart = c2.read(moneyLocalDataSourceProvider).all().length;
      c2.read(recurringMaterializerProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c2.read(moneyLocalDataSourceProvider).all().length, beforeRestart);
    });

    test('a rule whose day has not arrived does not post', () async {
      final store = InMemoryKeyValueStore();
      final c = container(DateTime(2026, 7, 5, 9), store);
      final before = c.read(moneyLocalDataSourceProvider).all().length;
      c.read(recurringProvider.notifier).addNew(
            label: 'Rent',
            type: TransactionType.expense,
            amountMinor: 100000,
            categoryId: DefaultCategories.home.id,
            dayOfMonth: 20,
          );
      c.read(recurringMaterializerProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.read(moneyLocalDataSourceProvider).all().length, before);
      expect(c.read(recurringProvider).single.lastRun, '');
    });

    test('RecurringRule JSON round-trips', () {
      const r = RecurringRule(
        id: 'r1',
        label: 'Netflix',
        type: TransactionType.expense,
        amountMinor: 1599,
        categoryId: 'expense_fun',
        dayOfMonth: 12,
        lastRun: '2026-06',
      );
      expect(RecurringRule.fromJson(r.toJson()), r);
    });
  });

  test('weekly report keeps net = income - spent', () {
    final c = container(DateTime(2026, 7, 15));
    final r = c.read(weeklyReportProvider);
    expect(r.net, r.income - r.spent);
    expect(r.spent.minorUnits, greaterThanOrEqualTo(0));
    expect(r.income.minorUnits, greaterThanOrEqualTo(0));
  });
}

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

class _FixedClock implements Clock {
  final DateTime t;
  const _FixedClock(this.t);
  @override
  DateTime now() => t;
}

void main() {
  Transaction ex(int major, Category c, DateTime d) => Transaction(
        id: 'e${d.day}${c.id}$major',
        amount: Money.fromMajor(major),
        type: TransactionType.expense,
        categoryId: c.id,
        date: d,
      );

  test('month comparison + daily spending', () async {
    final txs = [
      ex(100, DefaultCategories.food, DateTime(2026, 7, 5)), // this month
      ex(30, DefaultCategories.fun, DateTime(2026, 7, 6)),
      ex(200, DefaultCategories.food, DateTime(2026, 6, 3)), // last month
    ];
    final store = InMemoryKeyValueStore({
      'money.transactions': jsonEncode([for (final t in txs) t.toJson()]),
    });
    final c = ProviderContainer(overrides: [
      keyValueStoreProvider.overrideWithValue(store),
      clockProvider.overrideWithValue(_FixedClock(DateTime(2026, 7, 15))),
    ]);
    addTearDown(c.dispose);
    await c.read(transactionsProvider.future);

    final cmp = c.read(monthComparisonProvider);
    expect(cmp.thisSpent, Money.fromMajor(130).minorUnits);
    expect(cmp.lastSpent, Money.fromMajor(200).minorUnits);
    expect(cmp.pctChange, isNegative); // spent less than last month
    expect(cmp.topMoverCategory, DefaultCategories.food.id);
    expect(cmp.topMoverDelta, Money.fromMajor(-100).minorUnits); // 100 − 200

    final daily = c.read(dailySpendingProvider);
    expect(daily[5], Money.fromMajor(100).minorUnits);
    expect(daily[6], Money.fromMajor(30).minorUnits);
    expect(daily.containsKey(3), isFalse); // June not counted
  });
}

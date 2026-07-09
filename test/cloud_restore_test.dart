import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

void main() {
  test('InMemory store snapshot/putAll round-trips', () {
    final store = InMemoryKeyValueStore({'a': '1', 'b': '2'});
    final snap = store.snapshot();
    expect(snap, {'a': '1', 'b': '2'});

    final restored = InMemoryKeyValueStore();
    restored.putAll(snap);
    expect(restored.getString('a'), '1');
    expect(restored.getString('b'), '2');
  });

  test('restore: writing the store + bumping the data epoch reloads a repo',
      () {
    final store = InMemoryKeyValueStore();
    final container = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    // Fresh install → seed data present.
    expect(container.read(moneyLocalDataSourceProvider).all(),
        isNotEmpty);

    // Simulate a cloud restore: overwrite the money data, then bump the epoch.
    final restored = Transaction(
      id: 'restored-1',
      amount: Money.fromMajor(999),
      type: TransactionType.income,
      categoryId: DefaultCategories.salary.id,
      date: DateTime(2026, 7, 4),
    );
    store.setString(
      'money.transactions',
      jsonEncode([restored.toJson()]),
    );
    container.read(dataEpochProvider.notifier).state++;

    // The repository rebuilt from the restored data.
    final all = container.read(moneyLocalDataSourceProvider).all();
    expect(all.length, 1);
    expect(all.single.id, 'restored-1');
    expect(all.single.amount, Money.fromMajor(999));
  });
}

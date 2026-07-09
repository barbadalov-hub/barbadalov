import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Simulates two app launches sharing one store: a transaction added in the
/// first "launch" must be present in the second. This is the persistence
/// guarantee, verified without any platform channel.
void main() {
  test('transactions survive across app instances via the store', () async {
    final store = InMemoryKeyValueStore();
    ProviderContainer newLaunch() => ProviderContainer(
          overrides: [keyValueStoreProvider.overrideWithValue(store)],
        );

    // First launch: add a distinctive expense.
    final first = newLaunch();
    final added = await first.read(addTransactionProvider).call(
          amount: Money.fromMajor(123.45),
          type: TransactionType.expense,
          categoryId: DefaultCategories.food.id,
        );
    expect(added.isSuccess, isTrue);
    first.dispose();

    // Second launch, same store: the expense is loaded from persistence.
    final second = newLaunch();
    final all = await second.read(moneyRepositoryProvider).getAll();
    final list = all.valueOrNull ?? const [];
    expect(list.any((t) => t.amount.minorUnits == 12345), isTrue);
    second.dispose();
  });
}

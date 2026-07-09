import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Proves the iron rule end-to-end: a user action becomes an event, the
/// LifeCoreEngine dispatches it, and independent handlers react — here the
/// append-only log grows and the notification handler fires.
void main() {
  test('adding income flows event → engine → log + notification', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Boot the engine (registers log/notification/AI handlers).
    container.read(coreEngineProvider);
    final log = container.read(eventLogProvider);
    final before = log.length;

    final result = await container.read(addTransactionProvider).call(
      amount: Money.fromMajor(500),
      type: TransactionType.income,
      categoryId: DefaultCategories.salary.id,
    );
    expect(result.isSuccess, isTrue);

    // Let the async event dispatch drain.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // The event reached the append-only log...
    expect(log.length, greaterThan(before));
    // ...and the notification handler turned it into a user notification.
    final notifs = container.read(notificationRepositoryProvider).all();
    expect(notifs.any((n) => n.titleKey == 'notifMsg.income.title'), isTrue);
  });

  test('editing a transaction flows event → engine → log', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(coreEngineProvider);
    final log = container.read(eventLogProvider);

    final added = await container.read(addTransactionProvider).call(
      amount: Money.fromMajor(50),
      type: TransactionType.expense,
      categoryId: DefaultCategories.food.id,
    );
    final original = added.valueOrNull!;

    final edited = await container.read(updateTransactionProvider).call(
          Transaction(
            id: original.id,
            amount: Money.fromMajor(75),
            type: original.type,
            categoryId: DefaultCategories.fun.id,
            note: 'edited',
            date: original.date,
          ),
        );
    expect(edited.isSuccess, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // The stored transaction reflects the edit (same id, new amount/category).
    final all = await container.read(moneyRepositoryProvider).getAll();
    final stored =
        (all.valueOrNull ?? const []).firstWhere((t) => t.id == original.id);
    expect(stored.amount, Money.fromMajor(75));
    expect(stored.categoryId, DefaultCategories.fun.id);
    // The edit is part of the immutable life history.
    expect(log.entries.any((e) => e['type'] == 'transaction_updated'), isTrue);
  });

  test('removing a transaction flows event → engine → log', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(coreEngineProvider);
    final log = container.read(eventLogProvider);

    final added = await container.read(addTransactionProvider).call(
      amount: Money.fromMajor(42),
      type: TransactionType.expense,
      categoryId: DefaultCategories.food.id,
    );
    final transaction = added.valueOrNull!;

    final removed =
        await container.read(removeTransactionProvider).call(transaction);
    expect(removed.isSuccess, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Gone from the repository...
    final all = await container.read(moneyRepositoryProvider).getAll();
    expect(
      (all.valueOrNull ?? const []).any((t) => t.id == transaction.id),
      isFalse,
    );
    // ...and the removal itself is part of the immutable life history.
    expect(
      log.entries.any((e) => e['type'] == 'transaction_removed'),
      isTrue,
    );
  });
}

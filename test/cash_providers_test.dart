import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/ai/presentation/providers/ai_providers.dart';
import 'package:lifeos/features/money/presentation/providers/cash_providers.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

class _FixedClock implements Clock {
  final DateTime _now;
  const _FixedClock(this._now);
  @override
  DateTime now() => _now;
}

ProviderContainer _container({DateTime? at, KeyValueStore? store}) {
  final c = ProviderContainer(overrides: [
    clockProvider.overrideWithValue(
        _FixedClock(at ?? DateTime(2026, 8, 18, 12))),
    keyValueStoreProvider.overrideWithValue(store ?? InMemoryKeyValueStore()),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('the app admits it does not know the balance until told', () {
    final c = _container();
    expect(c.read(cashPositionProvider).anchored, isFalse);
    expect(c.read(balanceAnchorProvider), isNull);
  });

  test('stating a balance makes it the figure the whole app quotes', () {
    final c = _container();
    final beforeAnchor = c.read(safeToSpendProvider);

    c.read(balanceAnchorProvider.notifier).record(Money.fromMajor(3100));
    final after = c.read(cashPositionProvider);

    expect(after.anchored, isTrue);
    expect(after.onHand, Money.fromMajor(3100));
    expect(c.read(safeToSpendProvider), after.perDay);
    expect(c.read(safeToSpendProvider), isNot(beforeAnchor),
        reason: 'the honest figure must actually replace the month estimate');
  });

  test('the stated balance survives a restart', () {
    final store = InMemoryKeyValueStore();
    _container(store: store)
        .read(balanceAnchorProvider.notifier)
        .record(Money.fromMajor(750));

    // A second container is a fresh launch reading the same disk.
    final relaunched = _container(store: store);
    expect(relaunched.read(cashPositionProvider).onHand, Money.fromMajor(750));
  });

  test('removing the balance returns the app to not knowing', () {
    final store = InMemoryKeyValueStore();
    final c = _container(store: store);
    c.read(balanceAnchorProvider.notifier).record(Money.fromMajor(500));
    c.read(balanceAnchorProvider.notifier).forget();

    expect(c.read(cashPositionProvider).anchored, isFalse);
    expect(_container(store: store).read(balanceAnchorProvider), isNull,
        reason: 'forgetting must survive a restart too');
  });

  test('reading the balance from inside the engine does not close a cycle', () {
    // buildLifeContext runs inside an engine handler that the transaction
    // stream depends on. Reaching for safeToSpendProvider there is a circular
    // dependency that only shows up at runtime, so it is pinned here by name.
    final c = _container();
    c.read(balanceAnchorProvider.notifier).record(Money.fromMajor(1000));
    expect(() => c.read(transactionsProvider), returnsNormally);
    expect(() => c.read(aiInsightsProvider), returnsNormally);
  });

  test('the Money room and the Today headline cannot disagree', () {
    // Both read safeToSpendProvider; this pins that they resolve to one value
    // rather than two independently derived ones.
    final c = _container();
    c.read(balanceAnchorProvider.notifier).record(Money.fromMajor(1400));
    expect(c.read(safeToSpendProvider),
        c.read(cashPositionProvider).perDay);
  });
}

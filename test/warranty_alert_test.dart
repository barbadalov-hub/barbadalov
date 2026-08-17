import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/money/domain/entities/purchase.dart';
import 'package:lifeos/features/money/presentation/providers/warranty_alert_provider.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

class _FixedClock implements Clock {
  final DateTime _now;
  const _FixedClock(this._now);
  @override
  DateTime now() => _now;
}

Purchase _p(String id, DateTime? until, DateTime bought) => Purchase(
      id: id,
      title: id,
      price: Money.fromMajor(100),
      boughtAt: bought,
      until: until,
    );

void main() {
  final now = DateTime(2026, 6, 12);

  ProviderContainer harness(List<Purchase> seed,
      {KeyValueStore? store}) {
    final kv = store ?? InMemoryKeyValueStore({});
    final c = ProviderContainer(overrides: [
      keyValueStoreProvider.overrideWithValue(kv),
      clockProvider.overrideWithValue(_FixedClock(now)),
    ]);
    addTearDown(c.dispose);
    c.read(jsonStoreProvider).saveList<Purchase>(
        'purchases.list', seed, (p) => p.toJson());
    return c;
  }

  test('warns while the warranty can still be used', () async {
    final c = harness([_p('kettle', DateTime(2026, 6, 25), DateTime(2025, 6, 25))]);
    c.read(warrantyAlertServiceProvider);
    await Future<void>.delayed(Duration.zero);

    final notes = c.read(notificationRepositoryProvider).all();
    expect(notes.where((n) => n.id == 'warranty:kettle'), hasLength(1));
  });

  test('says nothing about cover with a year still to run', () async {
    final c = harness([_p('fridge', DateTime(2028, 1, 1), DateTime(2026, 1, 1))]);
    c.read(warrantyAlertServiceProvider);
    await Future<void>.delayed(Duration.zero);

    expect(c.read(notificationRepositoryProvider).all(), isEmpty,
        reason: 'cover that is nowhere near lapsing is not news');
  });

  test('says nothing about cover that already lapsed', () async {
    // Telling someone they missed it is not help — it is a reminder that they
    // lost, and there is nothing they can do with it.
    final c = harness([_p('old', DateTime(2025, 1, 1), DateTime(2024, 1, 1))]);
    c.read(warrantyAlertServiceProvider);
    await Future<void>.delayed(Duration.zero);

    expect(c.read(notificationRepositoryProvider).all(), isEmpty);
  });

  test('a purchase with no end date is never nagged about', () async {
    final c = harness([_p('unknown', null, DateTime(2026, 1, 1))]);
    c.read(warrantyAlertServiceProvider);
    await Future<void>.delayed(Duration.zero);

    expect(c.read(notificationRepositoryProvider).all(), isEmpty);
  });

  test('does not warn twice about the same thing across restarts', () async {
    final store = InMemoryKeyValueStore({});
    final purchases = [_p('kettle', DateTime(2026, 6, 25), DateTime(2025, 6, 25))];

    final first = harness(purchases, store: store);
    first.read(warrantyAlertServiceProvider);
    await Future<void>.delayed(Duration.zero);
    expect(first.read(notificationRepositoryProvider).all(), hasLength(1));

    // A fresh container is what a relaunch looks like. The dedup key lives in
    // the shared store, so the second run must raise nothing new — otherwise
    // the same warranty would nag once per app launch until it expired.
    final second = harness(purchases, store: store);
    second.read(warrantyAlertServiceProvider);
    await Future<void>.delayed(Duration.zero);

    expect(second.read(notificationRepositoryProvider).all(), isEmpty);
  });
}

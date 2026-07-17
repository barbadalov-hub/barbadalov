import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/food/presentation/providers/diet_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

class _FixedClock implements Clock {
  final DateTime _now;
  const _FixedClock(this._now);
  @override
  DateTime now() => _now;
}

ProviderContainer _container(InMemoryKeyValueStore store, DateTime now) =>
    ProviderContainer(overrides: [
      keyValueStoreProvider.overrideWithValue(store),
      clockProvider.overrideWithValue(_FixedClock(now)),
    ]);

void main() {
  test('toggle adds and removes checked items', () {
    final c = _container(InMemoryKeyValueStore(), DateTime(2026, 6, 10));
    addTearDown(c.dispose);
    final n = c.read(groceryCheckProvider.notifier);
    expect(c.read(groceryCheckProvider), isEmpty);
    n.toggle('eggs');
    expect(c.read(groceryCheckProvider), {'eggs'});
    n.toggle('milk');
    expect(c.read(groceryCheckProvider), {'eggs', 'milk'});
    n.toggle('eggs');
    expect(c.read(groceryCheckProvider), {'milk'});
  });

  test('clear empties the list', () {
    final c = _container(InMemoryKeyValueStore(), DateTime(2026, 6, 10));
    addTearDown(c.dispose);
    final n = c.read(groceryCheckProvider.notifier);
    n.toggle('eggs');
    n.toggle('milk');
    n.clear();
    expect(c.read(groceryCheckProvider), isEmpty);
  });

  test('checks persist within the same week token', () {
    final store = InMemoryKeyValueStore();
    final c1 = _container(store, DateTime(2026, 6, 10));
    c1.read(groceryCheckProvider.notifier).toggle('eggs');
    c1.dispose();

    final c2 = _container(store, DateTime(2026, 6, 11)); // same week
    addTearDown(c2.dispose);
    expect(c2.read(groceryCheckProvider), {'eggs'});
  });

  test('checks reset when the week changes', () {
    final store = InMemoryKeyValueStore();
    final c1 = _container(store, DateTime(2026, 6, 10));
    c1.read(groceryCheckProvider.notifier).toggle('eggs');
    c1.dispose();

    // ~3 weeks later → different week token → stale checks dropped.
    final c2 = _container(store, DateTime(2026, 7, 5));
    addTearDown(c2.dispose);
    expect(c2.read(groceryCheckProvider), isEmpty);
  });
}

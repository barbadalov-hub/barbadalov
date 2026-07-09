import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

class _FixedClock implements Clock {
  final DateTime _now;
  const _FixedClock(this._now);
  @override
  DateTime now() => _now;
}

void main() {
  test('weight history keeps one point per day and survives restart', () {
    final store = InMemoryKeyValueStore();
    ProviderContainer launch() => ProviderContainer(
          overrides: [keyValueStoreProvider.overrideWithValue(store)],
        );

    final first = launch();
    final log = first.read(logHealthProvider);
    log.logWeight(73.0);
    log.logWeight(72.6); // same day → replaces, not appends
    expect(first.read(weightHistoryProvider).length, 1);
    expect(first.read(weightHistoryProvider).single.$2, 72.6);
    first.dispose();

    final second = launch();
    expect(second.read(weightHistoryProvider).single.$2, 72.6);
    second.dispose();
  });

  test('a finished day is archived into history when a new day starts', () {
    final store = InMemoryKeyValueStore();
    ProviderContainer launchAt(DateTime now) => ProviderContainer(
          overrides: [
            keyValueStoreProvider.overrideWithValue(store),
            clockProvider.overrideWithValue(_FixedClock(now)),
          ],
        );

    // Day 1: walk 8000 steps.
    final day1 = launchAt(DateTime(2026, 7, 2, 20));
    day1.read(logHealthProvider).setSteps(8000);
    expect(day1.read(healthHistoryProvider), isEmpty);
    day1.dispose();

    // Day 2: yesterday lands in the archive; today starts fresh.
    final day2 = launchAt(DateTime(2026, 7, 3, 9));
    final history = day2.read(healthHistoryProvider);
    expect(history.length, 1);
    expect(history.single.steps, 8000);
    expect(day2.read(healthRepositoryProvider).today().steps, 0);
    day2.dispose();
  });
}

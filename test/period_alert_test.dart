import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_providers.dart';
import 'package:lifeos/features/wellness/domain/cycle.dart';
import 'package:lifeos/features/wellness/presentation/providers/wellness_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

class _FixedClock implements Clock {
  final DateTime t;
  const _FixedClock(this.t);
  @override
  DateTime now() => t;
}

void main() {
  test('CycleData JSON keeps the chosen protection', () {
    final d = CycleData(
      lastPeriodStart: DateTime(2026, 7, 1),
      protection: ProtectionType.tampons,
    );
    expect(CycleData.fromJson(d.toJson()), d);
  });

  ProviderContainer make(DateTime now, InMemoryKeyValueStore store) {
    final c = ProviderContainer(overrides: [
      keyValueStoreProvider.overrideWithValue(store),
      clockProvider.overrideWithValue(_FixedClock(now)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('raises a pre-period reminder 2 days out, once (deduped)', () async {
    final store = InMemoryKeyValueStore();
    // Cycle starts Jul 1 (28-day) → next period Jul 29. "Now" = Jul 27 → 2 days.
    final c = make(DateTime(2026, 7, 27), store);
    c.read(cycleProvider.notifier).save(CycleData(
          lastPeriodStart: DateTime(2026, 7, 1),
          protection: ProtectionType.tampons,
        ));

    final repo = c.read(notificationRepositoryProvider);
    c.read(cyclePeriodAlertServiceProvider);
    await Future<void>.delayed(Duration.zero);

    expect(repo.all(), hasLength(1));
    final n = repo.all().single;
    expect(n.titleKey, 'cycle.alert.title');
    expect(n.bodyKey, 'cycle.alert.soon');
    expect(n.params['n'], 2);
    expect(store.getString('wellness.periodAlerted'), isNotNull);

    // Simulated restart same day → no duplicate.
    final c2 = make(DateTime(2026, 7, 27), store);
    final repo2 = c2.read(notificationRepositoryProvider);
    c2.read(cyclePeriodAlertServiceProvider);
    await Future<void>.delayed(Duration.zero);
    expect(repo2.all(), isEmpty);
  });

  test('no reminder when the period is far away', () async {
    final store = InMemoryKeyValueStore();
    final c = make(DateTime(2026, 7, 10), store); // ~19 days out
    c.read(cycleProvider.notifier)
        .save(CycleData(lastPeriodStart: DateTime(2026, 7, 1)));
    final repo = c.read(notificationRepositoryProvider);
    c.read(cyclePeriodAlertServiceProvider);
    await Future<void>.delayed(Duration.zero);
    expect(repo.all(), isEmpty);
  });
}

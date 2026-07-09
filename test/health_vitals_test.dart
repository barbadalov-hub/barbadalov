import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/health/presentation/providers/health_goals_provider.dart';
import 'package:lifeos/features/health/presentation/providers/vitals_provider.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

void main() {
  test('vitals band classification', () {
    VitalsEntry v(int s, int d) =>
        VitalsEntry(date: DateTime(2026, 7, 1), systolic: s, diastolic: d, pulse: 60);
    expect(v(115, 75).bandKey, 'vitals.normal');
    expect(v(122, 78).bandKey, 'vitals.elevated');
    expect(v(132, 78).bandKey, 'vitals.high1');
    expect(v(145, 95).bandKey, 'vitals.high2');
    expect(v(118, 82).bandKey, 'vitals.high1'); // diastolic drives it
  });

  test('VitalsEntry JSON round-trips', () {
    final e = VitalsEntry(
        date: DateTime(2026, 7, 1), systolic: 120, diastolic: 80, pulse: 65);
    expect(VitalsEntry.fromJson(e.toJson()), e);
  });

  test('custom health goals persist across a reload', () {
    final store = InMemoryKeyValueStore();
    final c = ProviderContainer(
        overrides: [keyValueStoreProvider.overrideWithValue(store)]);
    addTearDown(c.dispose);

    expect(c.read(healthGoalsProvider).steps, HealthGoalSet.defaults.steps);
    c.read(healthGoalsProvider.notifier).save(
        const HealthGoalSet(steps: 12000, water: 10, sleep: 7.5));
    expect(c.read(healthGoalsProvider).steps, 12000);

    final c2 = ProviderContainer(
        overrides: [keyValueStoreProvider.overrideWithValue(store)]);
    addTearDown(c2.dispose);
    expect(c2.read(healthGoalsProvider).water, 10);
    expect(c2.read(healthGoalsProvider).sleep, 7.5);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/devices/device_health_source.dart';
import 'package:lifeos/core/services/health_score_service.dart';
import 'package:lifeos/features/health/application/health_use_cases.dart';
import 'package:lifeos/features/health/application/sync_device_health.dart';
import 'package:lifeos/features/health/data/health_repository_impl.dart';
import 'package:lifeos/features/health/domain/entities/health_day.dart';
import 'package:lifeos/features/health/domain/repositories/health_repository.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

final healthScoreServiceProvider =
    Provider<HealthScoreService>((ref) => const HealthScoreService());

const _daysKey = 'health.days';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final now = ref.watch(clockProvider).now();
  final store = ref.watch(jsonStoreProvider);
  const key = 'health.today';
  final today = DateTime(now.year, now.month, now.day);

  // Seed a partial day so rings aren't empty on the very first launch.
  final seed = HealthDay(
    date: today,
    steps: 4200,
    waterGlasses: 3,
    sleepHours: 6.5,
    weightKg: 72,
  );
  final stored = store.loadObject(key, HealthDay.fromJson, fallback: seed);

  // New day → archive the finished day into the rolling history (max 90) so
  // trends (steps, weight) can be charted, then reset counters (keep weight).
  if (!_isSameDay(stored.date, today)) {
    final history = store.loadList(_daysKey, HealthDay.fromJson,
        fallback: const <HealthDay>[]);
    final merged = [
      ...history.where((d) => !_isSameDay(d.date, stored.date)),
      stored,
    ]..sort((a, b) => a.date.compareTo(b.date));
    store.saveList(
      _daysKey,
      merged.length > 90 ? merged.sublist(merged.length - 90) : merged,
      (d) => d.toJson(),
    );
  }

  final initial = _isSameDay(stored.date, today)
      ? stored
      : HealthDay(date: today, weightKg: stored.weightKg);

  final impl = HealthRepositoryImpl(
    initial,
    onChanged: (day) => store.saveObject(key, day, (d) => d.toJson()),
  );
  ref.onDispose(impl.dispose);
  return impl;
});

/// Archived past days (oldest first). Depends on the repository provider so
/// the new-day archiving above is guaranteed to have run.
final healthHistoryProvider = Provider<List<HealthDay>>((ref) {
  ref.watch(healthRepositoryProvider);
  return ref
      .watch(jsonStoreProvider)
      .loadList(_daysKey, HealthDay.fromJson, fallback: const <HealthDay>[]);
});

/// Weight log over time: one point per day, persisted. Fed by
/// [LogHealth.logWeight] via callback.
class WeightHistoryController extends Notifier<List<(DateTime, double)>> {
  static const _key = 'health.weightHistory';

  @override
  List<(DateTime, double)> build() {
    final raw = ref.watch(jsonStoreProvider).loadList<Map<String, dynamic>>(
          _key,
          (j) => j,
          fallback: const [],
        );
    final points = [
      for (final e in raw)
        (DateTime.parse(e['date'] as String), (e['kg'] as num).toDouble()),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return points;
  }

  void record(DateTime date, double kg) {
    final day = DateTime(date.year, date.month, date.day);
    final next = [
      for (final p in state)
        if (p.$1 != day) p,
      (day, kg),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final trimmed = next.length > 180 ? next.sublist(next.length - 180) : next;
    ref.read(jsonStoreProvider).saveList<Map<String, dynamic>>(
      _key,
      [
        for (final p in trimmed)
          {'date': p.$1.toIso8601String(), 'kg': p.$2},
      ],
      (m) => m,
    );
    state = trimmed;
  }
}

final weightHistoryProvider =
    NotifierProvider<WeightHistoryController, List<(DateTime, double)>>(
        WeightHistoryController.new);

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

final todayHealthProvider = StreamProvider<HealthDay>((ref) {
  ref.watch(coreEngineProvider);
  return ref.watch(healthRepositoryProvider).watchToday();
});

/// The 0–100 health score for today (also feeds the Life Score health pillar).
final healthScoreProvider = Provider<int>((ref) {
  final day = ref.watch(todayHealthProvider).valueOrNull;
  if (day == null) return 50;
  return ref.watch(healthScoreServiceProvider).scoreFor(day);
});

final logHealthProvider = Provider<LogHealth>((ref) => LogHealth(
      ref.watch(healthRepositoryProvider),
      ref.watch(eventBusProvider),
      ref.watch(idServiceProvider),
      ref.watch(clockProvider),
      onWeightLogged: (date, kg) =>
          ref.read(weightHistoryProvider.notifier).record(date, kg),
    ));

// --- Phase 11: device integration -----------------------------------------
/// Which wearable/platform the user picked (Apple Watch, Google Fit, ...).
/// Persisted; drives the sync source label. On a phone build the real
/// `health`-package adapter reads the same selection (docs/DEVICES.md).
class SelectedDeviceController extends Notifier<String> {
  static const _key = 'device.selected';

  static const options = [
    'Apple Watch',
    'Google Fit',
    'Mi Band',
    'Garmin',
    'Fitbit',
  ];

  @override
  String build() =>
      ref.watch(keyValueStoreProvider).getString(_key) ?? options.first;

  void select(String name) {
    ref.read(keyValueStoreProvider).setString(_key, name);
    state = name;
  }
}

final selectedDeviceProvider =
    NotifierProvider<SelectedDeviceController, String>(
        SelectedDeviceController.new);

/// Swap `MockDeviceHealthSource` for a real `health`-package adapter to pull
/// from HealthKit / Google Fit / wearables. See docs/DEVICES.md.
final deviceHealthSourceProvider = Provider<DeviceHealthSource>((ref) =>
    MockDeviceHealthSource(deviceName: ref.watch(selectedDeviceProvider)));

final syncDeviceHealthProvider =
    Provider<SyncDeviceHealth>((ref) => SyncDeviceHealth(
          ref.watch(deviceHealthSourceProvider),
          ref.watch(logHealthProvider),
        ));

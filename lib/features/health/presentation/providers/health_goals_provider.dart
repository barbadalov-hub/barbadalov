import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/health/domain/entities/health_day.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// User-tunable daily goals (fall back to the built-in defaults).
class HealthGoalSet {
  final int steps;
  final int water;
  final double sleep;
  const HealthGoalSet({
    required this.steps,
    required this.water,
    required this.sleep,
  });

  static const defaults = HealthGoalSet(
    steps: HealthGoals.steps,
    water: HealthGoals.waterGlasses,
    sleep: HealthGoals.sleepHours,
  );

  HealthGoalSet copyWith({int? steps, int? water, double? sleep}) =>
      HealthGoalSet(
        steps: steps ?? this.steps,
        water: water ?? this.water,
        sleep: sleep ?? this.sleep,
      );
}

class HealthGoalsController extends Notifier<HealthGoalSet> {
  static const _key = 'health.goals';

  @override
  HealthGoalSet build() {
    final raw = ref.watch(keyValueStoreProvider).getString(_key);
    if (raw == null) return HealthGoalSet.defaults;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return HealthGoalSet(
        steps: (j['steps'] as num?)?.toInt() ?? HealthGoals.steps,
        water: (j['water'] as num?)?.toInt() ?? HealthGoals.waterGlasses,
        sleep: (j['sleep'] as num?)?.toDouble() ?? HealthGoals.sleepHours,
      );
    } catch (_) {
      return HealthGoalSet.defaults;
    }
  }

  void save(HealthGoalSet goals) {
    ref.read(keyValueStoreProvider).setString(
        _key,
        jsonEncode(
            {'steps': goals.steps, 'water': goals.water, 'sleep': goals.sleep}));
    state = goals;
  }
}

final healthGoalsProvider =
    NotifierProvider<HealthGoalsController, HealthGoalSet>(
        HealthGoalsController.new);

/// Days (archived + today) keyed by date-only, for streak math.
List<HealthDay> _allDays(Ref ref) {
  final days = [...ref.watch(healthHistoryProvider)];
  final today = ref.watch(todayHealthProvider).valueOrNull;
  if (today != null) days.add(today);
  return days;
}

int _streak(
  List<HealthDay> days,
  DateTime now,
  bool Function(HealthDay) met,
) {
  final byDay = {
    for (final d in days) DateTime(d.date.year, d.date.month, d.date.day): d,
  };
  var cursor = DateTime(now.year, now.month, now.day);
  // Today counts if already met; otherwise the streak survives on yesterday.
  final todayDay = byDay[cursor];
  if (todayDay == null || !met(todayDay)) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  var n = 0;
  while (true) {
    final d = byDay[cursor];
    if (d == null || !met(d)) break;
    n++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return n;
}

/// Consecutive days the step goal was hit (up to today).
final stepStreakProvider = Provider<int>((ref) {
  final goal = ref.watch(healthGoalsProvider).steps;
  return _streak(_allDays(ref), ref.watch(clockProvider).now(),
      (d) => d.steps >= goal);
});

/// Consecutive days the water goal was hit.
final hydrationStreakProvider = Provider<int>((ref) {
  final goal = ref.watch(healthGoalsProvider).water;
  return _streak(_allDays(ref), ref.watch(clockProvider).now(),
      (d) => d.waterGlasses >= goal);
});

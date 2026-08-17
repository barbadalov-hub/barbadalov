import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/goals/domain/entities/goal.dart';
import 'package:lifeos/features/goals/presentation/providers/goal_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

Goal _goal(String id, {double target = 1200, double saved = 0}) => Goal(
      id: id,
      title: id,
      emoji: '🎯',
      target: Money.fromMajor(target),
      saved: Money.fromMajor(saved),
    );

/// One pot of leftover money cannot fund three goals in full. Handing the whole
/// monthly leftover to each goal separately produced three completion dates
/// that could not all happen — the app promising the same money over again.
void main() {
  ProviderContainer harness({
    required List<Goal> goals,
    required double monthlyNet,
  }) {
    final container = ProviderContainer(overrides: [
      keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore({})),
      goalsProvider.overrideWith((ref) => Stream.value(goals)),
      monthlyNetProvider.overrideWithValue(Money.fromMajor(monthlyNet)),
    ]);
    addTearDown(container.dispose);
    // Resolve the goals stream so dependants see the list.
    container.read(goalsProvider);
    return container;
  }

  test('a single goal still gets the whole leftover', () async {
    final only = _goal('a', target: 1200);
    final c = harness(goals: [only], monthlyNet: 100);
    await c.read(goalsProvider.future);

    expect(c.read(activeGoalCountProvider), 1);
    expect(c.read(goalForecastProvider(only)).monthsRemaining, 12);
  });

  test('three goals divide it, so no date is promised twice', () async {
    final a = _goal('a', target: 1200);
    final c = harness(goals: [a, _goal('b'), _goal('c')], monthlyNet: 100);
    await c.read(goalsProvider.future);

    expect(c.read(activeGoalCountProvider), 3);
    // 1200 left at 33/month, not at 100/month.
    expect(c.read(goalForecastProvider(a)).monthsRemaining, 37);
  });

  test('finished goals stop taking a share', () async {
    final a = _goal('a', target: 1200);
    final done = _goal('b', target: 500, saved: 500);
    final c = harness(goals: [a, done], monthlyNet: 100);
    await c.read(goalsProvider.future);

    expect(done.isComplete, isTrue);
    expect(c.read(activeGoalCountProvider), 1,
        reason: 'a reached goal is not competing for next month’s money');
    expect(c.read(goalForecastProvider(a)).monthsRemaining, 12);
  });

  test('a leftover too small to split does not divide by zero', () async {
    final a = _goal('a', target: 1200);
    final c = harness(goals: [a, _goal('b'), _goal('c')], monthlyNet: 0);
    await c.read(goalsProvider.future);

    final f = c.read(goalForecastProvider(a));
    expect(f.monthsRemaining, isNull,
        reason: 'no spare money means no date, not an infinite one');
  });
}

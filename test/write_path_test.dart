import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/food/presentation/providers/food_providers.dart';
import 'package:lifeos/features/goals/presentation/providers/goal_providers.dart';
import 'package:lifeos/features/mind/presentation/providers/mind_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Exercises the write path for Mind/Goals/Food the way event_flow_test does for
/// money: a use case mutates its repository and (where applicable) the action
/// lands in the append-only event log via the Core Engine.
void main() {
  Future<void> drain() => Future<void>.delayed(const Duration(milliseconds: 50));

  test('adding then toggling a habit updates the repository and log', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(coreEngineProvider);
    final repo = container.read(mindRepositoryProvider);
    final log = container.read(eventLogProvider);

    final added = container.read(addHabitProvider).call(name: 'Meditate');
    expect(added.isSuccess, isTrue);
    final habit = added.valueOrNull!;
    expect(repo.habits().map((h) => h.name), contains('Meditate'));
    expect(habit.doneToday, isFalse);

    final before = log.length;
    container.read(toggleHabitProvider).call(habit);
    await drain();

    final toggled = repo.habits().firstWhere((h) => h.id == habit.id);
    expect(toggled.doneToday, isTrue);
    expect(toggled.streak, greaterThanOrEqualTo(1));
    expect(log.length, greaterThan(before)); // completion is in the life log
  });

  test('adding a goal and contributing updates saved and the log', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(coreEngineProvider);
    final repo = container.read(goalRepositoryProvider);
    final log = container.read(eventLogProvider);

    final before = log.length;
    final added = container.read(addGoalProvider).call(
          title: 'New laptop',
          target: Money.fromMajor(2000),
        );
    expect(added.isSuccess, isTrue);
    final goal = added.valueOrNull!;
    expect(repo.all().any((g) => g.id == goal.id), isTrue);

    container.read(contributeToGoalProvider).call(goal, Money.fromMajor(500));
    await drain();

    final saved = repo.all().firstWhere((g) => g.id == goal.id).saved;
    expect(saved, Money.fromMajor(500));
    expect(log.length, greaterThan(before));
  });

  test('rejects an empty goal title and a non-positive target', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(coreEngineProvider);

    final blank = container.read(addGoalProvider).call(
          title: '   ',
          target: Money.fromMajor(100),
        );
    final zero = container.read(addGoalProvider).call(
          title: 'Ok',
          target: const Money.zero(),
        );
    expect(blank.isSuccess, isFalse);
    expect(zero.isSuccess, isFalse);
  });

  test('adding a pantry item persists it and logs the event', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(coreEngineProvider);
    final repo = container.read(foodRepositoryProvider);
    final log = container.read(eventLogProvider);

    final before = log.length;
    final added = container.read(addFoodItemProvider).call(
          name: 'Yogurt',
          expiry: DateTime.now().add(const Duration(days: 2)),
        );
    expect(added.isSuccess, isTrue);
    await drain();

    expect(repo.pantry().map((i) => i.name), contains('Yogurt'));
    expect(log.length, greaterThan(before));
  });
}

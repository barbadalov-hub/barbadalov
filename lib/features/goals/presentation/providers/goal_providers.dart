import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/constants/app_constants.dart';
import 'package:lifeos/features/goals/application/forecast_goal.dart';
import 'package:lifeos/features/goals/application/goal_use_cases.dart';
import 'package:lifeos/features/goals/data/goal_repository_impl.dart';
import 'package:lifeos/features/goals/domain/entities/goal.dart';
import 'package:lifeos/features/goals/domain/goal_pace.dart';
import 'package:lifeos/features/goals/domain/repositories/goal_repository.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final now = ref.watch(clockProvider).now();
  final store = ref.watch(jsonStoreProvider);
  const key = 'goals.list';
  final impl = GoalRepositoryImpl(
    seed: store.loadList(key, Goal.fromJson,
        fallback:
            AppConstants.seedDemoData ? _defaultGoals(now) : const <Goal>[]),
    onChanged: (items) => store.saveList(key, items, (g) => g.toJson()),
  );
  ref.onDispose(impl.dispose);
  return impl;
});

List<Goal> _defaultGoals(DateTime now) => [
      Goal(
        id: 'seed_move',
        title: 'Move to a new city',
        emoji: '🏙️',
        target: Money.fromMajor(8000),
        saved: Money.fromMajor(2600),
        targetDate: DateTime(now.year + 1, now.month),
        milestones: const [
          Milestone(title: 'Research neighbourhoods', done: true),
          Milestone(title: 'Save 3 months rent'),
          Milestone(title: 'Book the movers'),
        ],
      ),
      Goal(
        id: 'seed_emergency',
        title: 'Emergency fund',
        emoji: '🛟',
        target: Money.fromMajor(5000),
        saved: Money.fromMajor(1500),
      ),
    ];

final goalsProvider = StreamProvider<List<Goal>>((ref) {
  ref.watch(coreEngineProvider);
  return ref.watch(goalRepositoryProvider).watch();
});

final forecastGoalProvider =
    Provider<ForecastGoal>((ref) => const ForecastGoal());

/// Monthly net savings used to project goals = this month's leftover budget.
final monthlyNetProvider = Provider<Money>((ref) {
  return ref.watch(currentBudgetProvider).available;
});

/// How many goals are still competing for the same leftover money.
final activeGoalCountProvider = Provider<int>((ref) {
  final all = ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
  return all.where((g) => !g.isComplete).length;
});

final goalForecastProvider = Provider.family<GoalForecast, Goal>((ref, goal) {
  final now = ref.watch(clockProvider).now();
  final monthlyNet = ref.watch(monthlyNetProvider);
  final active = ref.watch(activeGoalCountProvider);

  // One pot cannot fund every goal in full. Handing the whole leftover to each
  // goal separately promised the same money three times over and told the user
  // three different completion dates that could not all happen.
  final share = active <= 1
      ? monthlyNet
      : Money((monthlyNet.minorUnits / active).floor(),
          currency: monthlyNet.currency);

  return ref.watch(forecastGoalProvider).call(
        goal,
        monthlyNet: share,
        now: now,
      );
});

final addGoalProvider = Provider<AddGoal>((ref) => AddGoal(
      ref.watch(goalRepositoryProvider),
      ref.watch(eventBusProvider),
      ref.watch(idServiceProvider),
      ref.watch(clockProvider),
    ));

final contributeToGoalProvider =
    Provider<ContributeToGoal>((ref) => ContributeToGoal(
          ref.watch(goalRepositoryProvider),
          ref.watch(eventBusProvider),
          ref.watch(idServiceProvider),
          ref.watch(clockProvider),
          // A goal stores a running total, and a total cannot say whether it
          // took two weeks or two years. Each top-up is written down so the
          // room can forecast from behaviour rather than from intentions.
          onContributed: (goal, amount, at) => ref
              .read(goalContributionsProvider.notifier)
              .record(goal.id, amount.minorUnits, at),
        ));

/// The record of top-ups, kept because the event log lives only in memory and
/// is empty again on every launch.
class GoalContributionController extends Notifier<List<GoalContribution>> {
  static const _key = 'goals.contributions';

  /// Enough history for the six-month window with room to spare, capped so the
  /// list cannot grow without limit on an account used for years.
  static const _maxKept = 400;

  @override
  List<GoalContribution> build() =>
      ref.watch(jsonStoreProvider).loadList<GoalContribution>(
            _key,
            GoalContribution.fromJson,
            fallback: const [],
          );

  void record(String goalId, int minorUnits, DateTime at) {
    if (minorUnits <= 0) return;
    final next = [
      ...state,
      GoalContribution(goalId: goalId, minorUnits: minorUnits, at: at),
    ];
    // Oldest first, so trimming drops the entries the window ignores anyway.
    if (next.length > _maxKept) next.removeRange(0, next.length - _maxKept);
    ref
        .read(jsonStoreProvider)
        .saveList<GoalContribution>(_key, next, (c) => c.toJson());
    state = next;
  }

  List<GoalContribution> forGoal(String goalId) =>
      state.where((c) => c.goalId == goalId).toList();
}

final goalContributionsProvider =
    NotifierProvider<GoalContributionController, List<GoalContribution>>(
        GoalContributionController.new);

/// When a goal arrives at the rate its owner is actually saving — null until
/// there is enough history to say anything honest.
final goalPaceProvider = Provider.family<PaceEstimate?, Goal>((ref, goal) {
  return GoalPace.estimate(
    contributions:
        ref.watch(goalContributionsProvider.notifier).forGoal(goal.id),
    remainingMinor: goal.remaining.minorUnits,
    now: ref.watch(clockProvider).now(),
  );
});

final addMilestoneProvider = Provider<AddMilestone>(
    (ref) => AddMilestone(ref.watch(goalRepositoryProvider)));

final toggleMilestoneProvider = Provider<ToggleMilestone>(
    (ref) => ToggleMilestone(ref.watch(goalRepositoryProvider)));

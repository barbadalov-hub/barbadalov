import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/goals/domain/entities/goal.dart';
import 'package:lifeos/features/goals/presentation/providers/goal_providers.dart';
import 'package:lifeos/features/health/domain/entities/health_day.dart';
import 'package:lifeos/features/health/presentation/providers/health_goals_provider.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/features/mind/presentation/providers/mind_providers.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/features/rooms/domain/life_room.dart';
import 'package:lifeos/features/rooms/domain/room_attention.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Compact step count: 7 420 → "7.4k", 940 → "940".
String formatSteps(int steps) {
  if (steps < 1000) return '$steps';
  final k = steps / 1000;
  return k >= 10 ? '${k.round()}k' : '${k.toStringAsFixed(1)}k';
}

/// Hours as "6ч 30м" style parts, locale-formatted by the caller.
({int hours, int minutes}) splitHours(double hours) {
  final total = (hours * 60).round();
  return (hours: total ~/ 60, minutes: total % 60);
}

/// Which room, if any, gets the lead cover today — and why.
///
/// Reads the same providers the summaries do, so the headline can never
/// disagree with the numbers printed beside it.
final roomAttentionProvider = Provider<RoomAttention?>((ref) {
  final budget = ref.watch(currentBudgetProvider);
  final health = ref.watch(todayHealthProvider).valueOrNull;
  final habits = ref.watch(habitsProvider).valueOrNull ?? const [];
  final goals = ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
  final healthGoals = ref.watch(healthGoalsProvider);
  final now = ref.watch(clockProvider).now();

  final open = habits.where((h) => !h.doneToday).toList();

  return RoomAttentionBuilder.build(AttentionInput(
    hour: now.hour,
    overspent: budget.isOverspent,
    nothingToSpend: budget.safeToSpendToday.minorUnits <= 0,
    sleepHours: health?.sleepHours ?? 0,
    sleepGoal: healthGoals.sleep,
    steps: health?.steps ?? 0,
    stepGoal: healthGoals.steps,
    waterMl: health?.waterMl ?? 0,
    waterGoalMl: healthGoals.water * HealthDay.mlPerGlass,
    habitsTotal: habits.length,
    habitsDone: habits.length - open.length,
    lastOpenHabit: open.length == 1 ? open.first.name : null,
    goalsTotal: goals.length,
  ));
});

/// The four hero figures shown on the home grid, in [kLifeRooms] order.
final roomSummariesProvider = Provider<List<RoomSummary>>((ref) {
  final budget = ref.watch(currentBudgetProvider);
  final health = ref.watch(todayHealthProvider).valueOrNull;
  final habits = ref.watch(habitsProvider).valueOrNull ?? const [];
  final goals = ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];

  final doneHabits = habits.where((h) => h.doneToday).length;
  final sleep = splitHours(health?.sleepHours ?? 0);

  final active = goals.where((g) => !g.isComplete).toList();
  final goalPct = active.isEmpty
      ? (goals.isEmpty ? 0 : 100)
      : (active.first.progress * 100).round();

  return [
    RoomSummary(
      id: RoomId.money,
      hero: budget.safeToSpendToday.format(),
      subtitleKey: 'room.money.sub',
    ),
    RoomSummary(
      id: RoomId.body,
      hero: formatSteps(health?.steps ?? 0),
      subtitleKey: (health?.sleepHours ?? 0) > 0
          ? 'room.body.sub'
          : 'room.body.subNoSleep',
      params: {'h': sleep.hours, 'm': sleep.minutes},
    ),
    RoomSummary(
      id: RoomId.mind,
      hero: habits.isEmpty ? '—' : '$doneHabits/${habits.length}',
      subtitleKey: 'room.mind.sub',
    ),
    RoomSummary(
      id: RoomId.goals,
      hero: goals.isEmpty ? '—' : '$goalPct%',
      subtitleKey: goals.isEmpty ? 'room.goals.subNone' : 'room.goals.sub',
    ),
  ];
});

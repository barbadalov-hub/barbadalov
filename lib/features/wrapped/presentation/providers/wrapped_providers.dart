import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/goals/domain/entities/goal.dart';
import 'package:lifeos/features/goals/presentation/providers/goal_providers.dart';
import 'package:lifeos/features/history/presentation/providers/history_providers.dart';
import 'package:lifeos/features/home/presentation/providers/today_providers.dart';
import 'package:lifeos/features/lifeweeks/domain/life_weeks.dart';
import 'package:lifeos/features/mind/presentation/providers/mind_providers.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/features/wrapped/domain/wrapped_stats.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// The year LifeOS Wrapped currently recaps — defaults to the current calendar
/// year; the intro screen lets the user pick any year with data.
final wrappedYearProvider = StateProvider<int>((ref) {
  return ref.watch(clockProvider).now().year;
});

/// Years the user can recap: the current year plus every year the archive has
/// data for, newest first.
final wrappedAvailableYearsProvider = Provider<List<int>>((ref) {
  final years = <int>{ref.watch(clockProvider).now().year};
  for (final s in ref.watch(timelineProvider)) {
    years.add(s.year);
  }
  return years.toList()..sort((a, b) => b.compareTo(a));
});

/// The assembled year-in-review, combining the frozen monthly archive with a
/// few live headline figures (Life Score, best streak, goals, % of life lived).
final wrappedProvider = Provider<WrappedStats>((ref) {
  final year = ref.watch(wrappedYearProvider);
  final snapshots = ref.watch(timelineProvider);
  final goals = ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
  final profile = ref.watch(profileProvider);

  var savedMinor = 0;
  var completed = 0;
  for (final g in goals) {
    savedMinor += g.saved.minorUnits;
    if (g.isComplete) completed++;
  }

  return const WrappedBuilder().build(
    year: year,
    snapshots: snapshots,
    lifeScore: ref.watch(lifeScoreProvider).total,
    bestStreak: ref.watch(bestStreakProvider),
    goalsSavedMinor: savedMinor,
    goalsCompleted: completed,
    percentLived:
        profile == null ? 0 : LifeWeeks(ageYears: profile.age).percentLived,
  );
});

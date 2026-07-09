import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/i18n/locale_controller.dart';
import 'package:lifeos/features/coach/domain/coach_engine.dart';
import 'package:lifeos/features/goals/presentation/providers/goal_providers.dart';
import 'package:lifeos/features/home/presentation/providers/today_providers.dart';
import 'package:lifeos/features/insights/presentation/providers/insights_providers.dart';
import 'package:lifeos/features/mind/presentation/providers/mood_providers.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/features/reports/presentation/providers/report_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Assembles everything the coach reasons over from the live app state.
final coachContextProvider = Provider<CoachContext>((ref) {
  final profile = ref.watch(profileProvider);
  final score = ref.watch(lifeScoreProvider);
  final weekly = ref.watch(weeklyReportProvider);
  final budget = ref.watch(currentBudgetProvider);
  final mood = ref.watch(moodSummaryProvider);
  final goals = ref.watch(goalsProvider).valueOrNull ?? const [];
  final now = ref.watch(clockProvider).now();

  final lang = ref.watch(localeProvider)?.languageCode ?? 'en';
  final t = AppLocalizations(lang);
  final topCatName = weekly.topCategories.isEmpty
      ? ''
      : t.tr('cat.${weekly.topCategories.first.$1.id}');

  // The strongest cross-pillar pattern, phrased for the coach to cite.
  final correlations = ref.watch(insightsProvider).correlations;
  final insightSentence = correlations.isEmpty
      ? ''
      : t.tr(
          'insight.${correlations.first.driver.name}.${correlations.first.positive ? 'pos' : 'neg'}');

  var savedMinor = 0;
  var completed = 0;
  for (final g in goals) {
    savedMinor += g.saved.minorUnits;
    if (g.isComplete) completed++;
  }

  return CoachContext(
    name: profile?.name ?? '',
    lifeScore: score.total,
    finance: score.finance,
    health: score.health,
    discipline: score.discipline,
    productivity: score.productivity,
    netStr: weekly.net.format(),
    safeTodayStr: budget.safeToSpendToday.format(),
    availableStr: budget.available.format(),
    goalsSavedStr: Money(savedMinor).format(),
    topCatName: topCatName,
    avgSleep: weekly.avgSleep,
    avgWater: weekly.avgWater,
    avgMood: mood?.average ?? 0,
    avgMood30: mood?.last30 ?? 0,
    moodEntries: mood?.entries ?? 0,
    avgSteps: weekly.avgSteps,
    bestStreak: weekly.bestStreak,
    loggingStreak: ref.watch(insightsProvider).loggingStreak,
    habitsDone: weekly.habitsDone,
    habitsTotal: weekly.habitsTotal,
    goalsCompleted: completed,
    seed: now.difference(DateTime(now.year)).inDays,
    insightSentence: insightSentence,
  );
});

/// The single proactive coach tip to surface on Today, chosen from the most
/// actionable signal in the current context.
final coachTipProvider = Provider<CoachReply>((ref) {
  const engine = CoachEngine();
  final ctx = ref.watch(coachContextProvider);
  return engine.reply(engine.suggestOfTheDay(ctx), ctx);
});

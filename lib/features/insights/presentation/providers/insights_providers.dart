import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/health/domain/entities/health_day.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/features/insights/domain/insight_engine.dart';
import 'package:lifeos/features/insights/domain/logging_streak.dart';
import 'package:lifeos/features/insights/domain/mood_patterns.dart';
import 'package:lifeos/features/mind/domain/mood.dart';
import 'package:lifeos/features/mind/presentation/providers/mind_providers.dart';
import 'package:lifeos/features/mind/presentation/providers/mood_providers.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// The assembled Insights screen model: discovered correlations + single-metric
/// highlights that show up even before there's enough data to correlate.
class InsightsData {
  final List<LifeInsight> correlations;
  final int pairedDays; // days that had a mood to correlate against
  final int trackedDays; // distinct logged days in the last 30
  final int bestStreak;
  final int loggingStreak; // consecutive days you logged anything
  final MoodEntry? bestMoodDay;
  final HealthDay? peakStepsDay;

  // Mood patterns (Insights v2).
  final List<MoodCorrelation> activityImpacts; // strongest first, |delta| ranked
  final WeekdayMood? bestWeekday;
  final MoodTrend? trend;

  const InsightsData({
    this.correlations = const [],
    this.pairedDays = 0,
    this.trackedDays = 0,
    this.bestStreak = 0,
    this.loggingStreak = 0,
    this.bestMoodDay,
    this.peakStepsDay,
    this.activityImpacts = const [],
    this.bestWeekday,
    this.trend,
  });

  bool get hasAny =>
      correlations.isNotEmpty ||
      bestMoodDay != null ||
      peakStepsDay != null ||
      bestStreak > 0 ||
      activityImpacts.isNotEmpty ||
      bestWeekday != null ||
      trend != null;
}

int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

final insightsProvider = Provider<InsightsData>((ref) {
  final now = ref.watch(clockProvider).now();
  final moods = ref.watch(moodLogProvider);
  final days = [...ref.watch(healthHistoryProvider)];
  final today = ref.watch(todayHealthProvider).valueOrNull;
  if (today != null) days.add(today);
  final txs = ref.watch(transactionsProvider).valueOrNull ?? const [];

  final healthByDay = {for (final h in days) _dayKey(h.date): h};
  final spendByDay = <int, int>{};
  for (final t in txs) {
    if (t.isExpense) {
      final k = _dayKey(t.date);
      spendByDay[k] = (spendByDay[k] ?? 0) + t.amount.minorUnits;
    }
  }

  // One correlation point per day that has a mood.
  final points = <InsightPoint>[];
  for (final m in moods) {
    final k = _dayKey(m.date);
    final h = healthByDay[k];
    points.add(InsightPoint(
      mood: m.mood.toDouble(),
      sleepHours: (h != null && h.sleepHours > 0) ? h.sleepHours : null,
      steps: (h != null && h.steps > 0) ? h.steps.toDouble() : null,
      water: (h != null && h.waterGlasses > 0) ? h.waterGlasses.toDouble() : null,
      spendMajor: (spendByDay[k] ?? 0) / 100.0,
      stress: (h != null && h.stress > 0) ? h.stress.toDouble() : null,
    ));
  }

  final correlations = const InsightEngine().correlate(points);

  // Highlights.
  MoodEntry? bestMood;
  for (final m in moods) {
    if (bestMood == null ||
        m.mood > bestMood.mood ||
        (m.mood == bestMood.mood && m.date.isAfter(bestMood.date))) {
      bestMood = m;
    }
  }
  HealthDay? peakSteps;
  for (final h in days) {
    if (h.steps > 0 && (peakSteps == null || h.steps > peakSteps.steps)) {
      peakSteps = h;
    }
  }

  // Distinct logged days in the last 30.
  final cutoff = now.subtract(const Duration(days: 30));
  final logged = <int>{};
  bool recent(DateTime d) => d.isAfter(cutoff);
  for (final m in moods) {
    if (recent(m.date)) logged.add(_dayKey(m.date));
  }
  for (final h in days) {
    if (recent(h.date) &&
        (h.steps > 0 || h.sleepHours > 0 || h.waterGlasses > 0)) {
      logged.add(_dayKey(h.date));
    }
  }
  for (final t in txs) {
    if (recent(t.date)) logged.add(_dayKey(t.date));
  }

  // All-time set of logged days (no 30-day cap) for the "days in a row" streak.
  final allLogged = <int>{
    for (final m in moods) _dayKey(m.date),
    for (final h in days)
      if (h.steps > 0 || h.sleepHours > 0 || h.waterGlasses > 0)
        _dayKey(h.date),
    for (final t in txs) _dayKey(t.date),
  };

  // Mood patterns (v2): which activities move mood, the happiest weekday, and
  // the two-week trend.
  final summary = ref.watch(moodSummaryProvider);
  final impacts = summary == null
      ? const <MoodCorrelation>[]
      : [for (final c in summary.correlations) if (c.delta.abs() >= 0.25) c]
          .take(6)
          .toList();

  return InsightsData(
    correlations: correlations,
    pairedDays: points.length,
    trackedDays: logged.length,
    bestStreak: ref.watch(bestStreakProvider),
    loggingStreak: loggingStreak(allLogged, now),
    bestMoodDay: bestMood,
    peakStepsDay: peakSteps,
    activityImpacts: impacts,
    bestWeekday: bestMoodWeekday(moods),
    trend: moodTrend(moods, now),
  );
});

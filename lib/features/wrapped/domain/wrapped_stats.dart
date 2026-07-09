import 'package:lifeos/features/history/domain/monthly_snapshot.dart';

/// The year-in-review numbers behind "LifeOS Wrapped" — a shareable, Spotify-
/// Wrapped-style recap of one calendar year across every pillar. Aggregated from
/// the frozen [MonthlySnapshot] archive plus a few live headline figures.
class WrappedStats {
  final int year;
  final int monthsTracked;

  // Money (whole-year totals, minor units of the default currency).
  final int incomeMinor;
  final int spentMinor;
  final String? topCategoryId;

  // Health.
  final int avgSteps; // mean of months that logged steps
  final int totalSteps; // estimated steps walked across the year
  final double avgSleep; // hours
  final double? weightDeltaKg; // last logged − first logged

  // Mind & mood.
  final double avgMood; // 1..5, 0 if none
  final int moodMonths; // months with a mood average

  // Live headline figures (current state, not year-scoped).
  final int lifeScore;
  final int bestStreak;
  final int goalsSavedMinor;
  final int goalsCompleted;
  final int percentLived; // life-in-weeks

  const WrappedStats({
    required this.year,
    this.monthsTracked = 0,
    this.incomeMinor = 0,
    this.spentMinor = 0,
    this.topCategoryId,
    this.avgSteps = 0,
    this.totalSteps = 0,
    this.avgSleep = 0,
    this.weightDeltaKg,
    this.avgMood = 0,
    this.moodMonths = 0,
    this.lifeScore = 0,
    this.bestStreak = 0,
    this.goalsSavedMinor = 0,
    this.goalsCompleted = 0,
    this.percentLived = 0,
  });

  int get netMinor => incomeMinor - spentMinor;

  bool get hasData =>
      monthsTracked > 0 ||
      moodMonths > 0 ||
      goalsSavedMinor > 0 ||
      bestStreak > 0;
}

/// Pure aggregator: folds a year's [MonthlySnapshot]s (plus live extras) into a
/// single [WrappedStats].
class WrappedBuilder {
  const WrappedBuilder();

  WrappedStats build({
    required int year,
    required List<MonthlySnapshot> snapshots,
    int lifeScore = 0,
    int bestStreak = 0,
    int goalsSavedMinor = 0,
    int goalsCompleted = 0,
    int percentLived = 0,
  }) {
    final ys = snapshots.where((s) => s.year == year).toList()
      ..sort((a, b) => a.ym.compareTo(b.ym));

    var income = 0, spent = 0, totalSteps = 0;
    var stepSum = 0, stepMonths = 0;
    var sleepSum = 0.0, sleepMonths = 0;
    var moodSum = 0.0, moodMonths = 0;
    final catCount = <String, int>{};
    double? firstW, lastW;

    for (final s in ys) {
      income += s.incomeMinor;
      spent += s.spentMinor;
      if (s.avgSteps > 0) {
        stepSum += s.avgSteps;
        stepMonths++;
        totalSteps += s.avgSteps * _daysInMonth(s.year, s.month);
      }
      if (s.avgSleep > 0) {
        sleepSum += s.avgSleep;
        sleepMonths++;
      }
      if (s.avgMood != null) {
        moodSum += s.avgMood!;
        moodMonths++;
      }
      if (s.topCategoryId != null) {
        catCount.update(s.topCategoryId!, (v) => v + 1, ifAbsent: () => 1);
      }
      if (s.weightKg != null) {
        firstW ??= s.weightKg;
        lastW = s.weightKg;
      }
    }

    String? topCat;
    if (catCount.isNotEmpty) {
      final sorted = catCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topCat = sorted.first.key;
    }

    return WrappedStats(
      year: year,
      monthsTracked: ys.length,
      incomeMinor: income,
      spentMinor: spent,
      topCategoryId: topCat,
      avgSteps: stepMonths == 0 ? 0 : (stepSum / stepMonths).round(),
      totalSteps: totalSteps,
      avgSleep: sleepMonths == 0 ? 0 : sleepSum / sleepMonths,
      weightDeltaKg:
          (firstW != null && lastW != null) ? lastW - firstW : null,
      avgMood: moodMonths == 0 ? 0 : moodSum / moodMonths,
      moodMonths: moodMonths,
      lifeScore: lifeScore,
      bestStreak: bestStreak,
      goalsSavedMinor: goalsSavedMinor,
      goalsCompleted: goalsCompleted,
      percentLived: percentLived,
    );
  }

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
}

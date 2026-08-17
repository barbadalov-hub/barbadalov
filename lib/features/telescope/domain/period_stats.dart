import 'package:lifeos/features/health/domain/entities/health_day.dart';
import 'package:lifeos/features/mind/domain/mood.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';

/// How far the telescope is zoomed out. The point of the app: the same life,
/// read at different distances.
enum TimeZoom { d3, d7, d30, all }

extension TimeZoomX on TimeZoom {
  /// Window length in days; null means "everything ever logged".
  int? get days => switch (this) {
        TimeZoom.d3 => 3,
        TimeZoom.d7 => 7,
        TimeZoom.d30 => 30,
        TimeZoom.all => null,
      };

  String get labelKey => switch (this) {
        TimeZoom.d3 => 'zoom.d3',
        TimeZoom.d7 => 'zoom.d7',
        TimeZoom.d30 => 'zoom.d30',
        TimeZoom.all => 'zoom.all',
      };
}

/// Everything the telescope shows for one window. Money stays in minor units;
/// averages cover only the days that actually logged that metric, so a missed
/// day never silently drags an average to zero.
class PeriodStats {
  final TimeZoom zoom;
  final int spentMinor;
  final int incomeMinor;
  final String? topCategoryId;
  final int avgSteps;
  final int totalSteps;
  final double avgSleep;
  final double avgWater;
  final double avgMood;
  final int moodDays;
  final int daysTracked;
  final int peakSteps;

  const PeriodStats({
    required this.zoom,
    this.spentMinor = 0,
    this.incomeMinor = 0,
    this.topCategoryId,
    this.avgSteps = 0,
    this.totalSteps = 0,
    this.avgSleep = 0,
    this.avgWater = 0,
    this.avgMood = 0,
    this.moodDays = 0,
    this.daysTracked = 0,
    this.peakSteps = 0,
  });

  int get netMinor => incomeMinor - spentMinor;

  bool get hasData =>
      daysTracked > 0 || spentMinor > 0 || incomeMinor > 0 || moodDays > 0;
}

int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

/// Folds raw logs into one [PeriodStats]. Pure — no providers, no clock.
class PeriodStatsBuilder {
  const PeriodStatsBuilder();

  PeriodStats build({
    required TimeZoom zoom,
    required DateTime now,
    required List<Transaction> transactions,
    required List<HealthDay> days,
    required List<MoodEntry> moods,
  }) {
    final span = zoom.days;
    final today = DateTime(now.year, now.month, now.day);
    // An N-day window includes today, so it starts N-1 days back.
    final from = span == null ? null : today.subtract(Duration(days: span - 1));
    bool inWindow(DateTime d) {
      if (from == null) return !DateTime(d.year, d.month, d.day).isAfter(today);
      final x = DateTime(d.year, d.month, d.day);
      return !x.isBefore(from) && !x.isAfter(today);
    }

    var spent = 0, income = 0;
    final byCat = <String, int>{};
    final logged = <int>{};
    for (final t in transactions) {
      if (!inWindow(t.date)) continue;
      logged.add(_dayKey(t.date));
      if (t.isExpense) {
        spent += t.amount.minorUnits;
        byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount.minorUnits;
      } else {
        income += t.amount.minorUnits;
      }
    }
    String? topCat;
    if (byCat.isNotEmpty) {
      topCat = (byCat.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .first
          .key;
    }

    var stepSum = 0, stepDays = 0, totalSteps = 0, peakSteps = 0;
    var sleepSum = 0.0, sleepDays = 0;
    var waterSum = 0.0, waterDays = 0;
    for (final d in days) {
      if (!inWindow(d.date)) continue;
      final any = d.steps > 0 || d.sleepHours > 0 || d.waterGlasses > 0;
      if (any) logged.add(_dayKey(d.date));
      if (d.steps > 0) {
        stepSum += d.steps;
        stepDays++;
        totalSteps += d.steps;
        if (d.steps > peakSteps) peakSteps = d.steps;
      }
      if (d.sleepHours > 0) {
        sleepSum += d.sleepHours;
        sleepDays++;
      }
      if (d.waterGlasses > 0) {
        waterSum += d.waterGlasses;
        waterDays++;
      }
    }

    var moodSum = 0.0, moodDays = 0;
    for (final m in moods) {
      if (!inWindow(m.date)) continue;
      logged.add(_dayKey(m.date));
      moodSum += m.mood;
      moodDays++;
    }

    return PeriodStats(
      zoom: zoom,
      spentMinor: spent,
      incomeMinor: income,
      topCategoryId: topCat,
      avgSteps: stepDays == 0 ? 0 : (stepSum / stepDays).round(),
      totalSteps: totalSteps,
      peakSteps: peakSteps,
      avgSleep: sleepDays == 0 ? 0 : sleepSum / sleepDays,
      avgWater: waterDays == 0 ? 0 : waterSum / waterDays,
      avgMood: moodDays == 0 ? 0 : moodSum / moodDays,
      moodDays: moodDays,
      daysTracked: logged.length,
    );
  }
}

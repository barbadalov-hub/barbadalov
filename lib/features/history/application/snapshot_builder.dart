import 'package:lifeos/features/health/domain/entities/health_day.dart';
import 'package:lifeos/features/history/domain/monthly_snapshot.dart';
import 'package:lifeos/features/mind/domain/mood.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';

/// Builds a [MonthlySnapshot] for [ym] (year*100+month) from the raw logs we
/// still have. Pure & deterministic — the history archiver calls it per month.
class SnapshotBuilder {
  const SnapshotBuilder();

  MonthlySnapshot build({
    required int ym,
    required List<Transaction> transactions,
    required List<MoodEntry> moods,
    required List<HealthDay> days,
    required List<(DateTime, double)> weights,
  }) {
    final year = ym ~/ 100;
    final month = ym % 100;
    bool inMonth(DateTime d) => d.year == year && d.month == month;

    var spent = 0;
    var income = 0;
    final byCat = <String, int>{};
    for (final t in transactions) {
      if (!inMonth(t.date)) continue;
      if (t.isExpense) {
        spent += t.amount.minorUnits;
        byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount.minorUnits;
      } else {
        income += t.amount.minorUnits;
      }
    }
    String? topCat;
    var topVal = 0;
    byCat.forEach((k, v) {
      if (v > topVal) {
        topVal = v;
        topCat = k;
      }
    });

    final monthMoods = moods.where((m) => inMonth(m.date)).toList();
    final avgMood = monthMoods.isEmpty
        ? null
        : monthMoods.map((m) => m.mood).reduce((a, b) => a + b) /
            monthMoods.length;

    final monthDays = days.where((d) => inMonth(d.date)).toList();
    int avgSteps = 0;
    double avgWater = 0;
    double avgSleep = 0;
    if (monthDays.isNotEmpty) {
      avgSteps = (monthDays.map((d) => d.steps).reduce((a, b) => a + b) /
              monthDays.length)
          .round();
      avgWater =
          monthDays.map((d) => d.waterGlasses).reduce((a, b) => a + b) /
              monthDays.length;
      avgSleep = monthDays.map((d) => d.sleepHours).reduce((a, b) => a + b) /
          monthDays.length;
    }

    // Last weight reading in (or before) the month.
    double? weight;
    for (final (date, kg) in weights) {
      if (date.year < year || (date.year == year && date.month <= month)) {
        weight = kg;
      }
    }

    return MonthlySnapshot(
      ym: ym,
      spentMinor: spent,
      incomeMinor: income,
      topCategoryId: topCat,
      avgMood: avgMood,
      avgSteps: avgSteps,
      avgWater: avgWater,
      avgSleep: avgSleep,
      weightKg: weight,
    );
  }
}

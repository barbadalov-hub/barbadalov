import 'package:lifeos/features/food/domain/entities/nutrition.dart';

/// One day of eating, as the review sees it.
class DietDay {
  final DateTime date;
  final NutritionFacts totals;
  const DietDay({required this.date, required this.totals});

  bool get logged => totals.kcal > 0;
}

/// What a week of eating looked like.
class WeeklyDiet {
  /// Days in the window that have any food logged at all.
  final int daysLogged;

  /// Average calories across the **logged** days only.
  ///
  /// Dividing by seven would report someone who ate carefully on three days
  /// and forgot to log the rest as eating 900 calories a day, which is not
  /// what happened and is exactly the kind of number that scares people.
  final int avgKcal;

  final int avgProteinG;
  final int avgFatG;
  final int avgCarbsG;

  /// Days within [WeeklyDietReview.onTargetTolerance] of the target.
  final int daysOnTarget;
  final int daysOver;
  final int daysUnder;

  /// The target this was measured against, or null when there is no profile
  /// to derive one from.
  final int? targetKcal;

  const WeeklyDiet({
    this.daysLogged = 0,
    this.avgKcal = 0,
    this.avgProteinG = 0,
    this.avgFatG = 0,
    this.avgCarbsG = 0,
    this.daysOnTarget = 0,
    this.daysOver = 0,
    this.daysUnder = 0,
    this.targetKcal,
  });

  bool get hasEnough => daysLogged >= WeeklyDietReview.minDays;

  /// Share of calories from protein, fat and carbs — the split people actually
  /// want to see, rather than three unrelated gram figures.
  ({int protein, int fat, int carbs})? get macroSplit {
    final kcal = avgProteinG * 4 + avgFatG * 9 + avgCarbsG * 4;
    if (kcal <= 0) return null;
    return (
      protein: (avgProteinG * 4 * 100 / kcal).round(),
      fat: (avgFatG * 9 * 100 / kcal).round(),
      carbs: (avgCarbsG * 4 * 100 / kcal).round(),
    );
  }

  /// The single sentence worth leading with, as an i18n key.
  String get verdictKey {
    if (!hasEnough) return 'wdiet.needMore';
    if (targetKcal == null) return 'wdiet.noTarget';
    if (daysOver > daysOnTarget && daysOver >= daysUnder) return 'wdiet.over';
    if (daysUnder > daysOnTarget && daysUnder > daysOver) return 'wdiet.under';
    return 'wdiet.steady';
  }
}

/// Builds the weekly review. Pure, so the judgement can be tested.
class WeeklyDietReview {
  const WeeklyDietReview();

  /// Fewer logged days than this and there is nothing honest to summarise —
  /// two days is an anecdote, not a week.
  static const minDays = 3;

  /// How far from the target still counts as hitting it. Nobody eats to the
  /// calorie, and a review that calls 2 090 a miss against 2 000 is a review
  /// people stop reading.
  static const onTargetTolerance = 0.12;

  WeeklyDiet build({
    required List<DietDay> days,
    required DateTime now,
    int? targetKcal,
    int window = 7,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(Duration(days: window - 1));

    final inWindow = days.where((d) {
      final x = DateTime(d.date.year, d.date.month, d.date.day);
      return !x.isBefore(from) && !x.isAfter(today) && d.logged;
    }).toList();

    if (inWindow.isEmpty) {
      return WeeklyDiet(targetKcal: targetKcal);
    }

    var kcal = 0, protein = 0, fat = 0, carbs = 0;
    var onTarget = 0, over = 0, under = 0;
    for (final d in inWindow) {
      kcal += d.totals.kcal;
      protein += d.totals.proteinG;
      fat += d.totals.fatG;
      carbs += d.totals.carbsG;

      if (targetKcal != null && targetKcal > 0) {
        final delta = (d.totals.kcal - targetKcal) / targetKcal;
        if (delta.abs() <= onTargetTolerance) {
          onTarget++;
        } else if (delta > 0) {
          over++;
        } else {
          under++;
        }
      }
    }

    final n = inWindow.length;
    return WeeklyDiet(
      daysLogged: n,
      avgKcal: (kcal / n).round(),
      avgProteinG: (protein / n).round(),
      avgFatG: (fat / n).round(),
      avgCarbsG: (carbs / n).round(),
      daysOnTarget: onTarget,
      daysOver: over,
      daysUnder: under,
      targetKcal: targetKcal,
    );
  }
}

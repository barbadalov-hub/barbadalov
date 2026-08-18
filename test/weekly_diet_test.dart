import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/domain/weekly_diet.dart';

DietDay _d(DateTime date, int kcal,
        {int p = 0, int f = 0, int c = 0}) =>
    DietDay(
      date: date,
      totals: NutritionFacts(kcal: kcal, proteinG: p, fatG: f, carbsG: c),
    );

void main() {
  const review = WeeklyDietReview();
  final now = DateTime(2026, 8, 18);
  DateTime ago(int days) => now.subtract(Duration(days: days));

  test('averages over the days that were logged, not over seven', () {
    // Someone who logged three careful days and forgot the rest did not eat
    // 900 a day, and telling them so would be alarming and false.
    final w = review.build(
      days: [_d(ago(0), 2000), _d(ago(1), 2100), _d(ago(2), 1900)],
      now: now,
      targetKcal: 2000,
    );
    expect(w.daysLogged, 3);
    expect(w.avgKcal, 2000);
  });

  test('ignores days outside the window', () {
    final w = review.build(
      days: [_d(ago(0), 2000), _d(ago(20), 5000)],
      now: now,
    );
    expect(w.daysLogged, 1);
    expect(w.avgKcal, 2000);
  });

  group('hitting the target', () {
    test('near enough counts as on target', () {
      // 2 090 against 2 000 is a hit. A review that calls it a miss is one
      // people stop reading.
      final w = review.build(
        days: [_d(ago(0), 2090), _d(ago(1), 1920), _d(ago(2), 2000)],
        now: now,
        targetKcal: 2000,
      );
      expect(w.daysOnTarget, 3);
      expect(w.verdictKey, 'wdiet.steady');
    });

    test('consistently over is said plainly', () {
      final w = review.build(
        days: [_d(ago(0), 2800), _d(ago(1), 2900), _d(ago(2), 3000)],
        now: now,
        targetKcal: 2000,
      );
      expect(w.daysOver, 3);
      expect(w.verdictKey, 'wdiet.over');
    });

    test('consistently under is said too', () {
      final w = review.build(
        days: [_d(ago(0), 1200), _d(ago(1), 1100), _d(ago(2), 1300)],
        now: now,
        targetKcal: 2000,
      );
      expect(w.daysUnder, 3);
      expect(w.verdictKey, 'wdiet.under');
    });
  });

  group('when it refuses to summarise', () {
    test('two days is an anecdote, not a week', () {
      final w = review.build(
        days: [_d(ago(0), 2000), _d(ago(1), 2000)],
        now: now,
        targetKcal: 2000,
      );
      expect(w.hasEnough, isFalse);
      expect(w.verdictKey, 'wdiet.needMore');
    });

    test('an empty diary produces no numbers rather than zeroes', () {
      final w = review.build(days: const [], now: now, targetKcal: 2000);
      expect(w.daysLogged, 0);
      expect(w.avgKcal, 0);
      expect(w.hasEnough, isFalse);
    });

    test('without a profile it reports but does not judge', () {
      final w = review.build(
        days: [_d(ago(0), 2000), _d(ago(1), 2200), _d(ago(2), 1800)],
        now: now,
      );
      expect(w.avgKcal, 2000);
      expect(w.verdictKey, 'wdiet.noTarget',
          reason: 'no target means no basis for calling a day over or under');
    });
  });

  test('the macro split adds up to roughly a hundred percent', () {
    final w = review.build(
      days: [
        _d(ago(0), 2000, p: 150, f: 60, c: 200),
        _d(ago(1), 2000, p: 150, f: 60, c: 200),
        _d(ago(2), 2000, p: 150, f: 60, c: 200),
      ],
      now: now,
    );
    final split = w.macroSplit!;
    expect(split.protein + split.fat + split.carbs, inInclusiveRange(99, 101));
    expect(split.protein, greaterThan(20));
  });

  test('a day with no macros logged has no split to show', () {
    final w = review.build(
      days: [_d(ago(0), 500), _d(ago(1), 500), _d(ago(2), 500)],
      now: now,
    );
    expect(w.macroSplit, isNull);
  });
}

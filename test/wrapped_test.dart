import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/history/domain/monthly_snapshot.dart';
import 'package:lifeos/features/wrapped/domain/wrapped_stats.dart';

void main() {
  group('WrappedBuilder', () {
    const builder = WrappedBuilder();

    final snapshots = <MonthlySnapshot>[
      // Previous year — must be ignored.
      const MonthlySnapshot(ym: 202512, spentMinor: 999999, incomeMinor: 999999),
      const MonthlySnapshot(
        ym: 202601,
        spentMinor: 30000,
        incomeMinor: 50000,
        topCategoryId: 'expense_food',
        avgMood: 4,
        avgSteps: 10000,
        avgSleep: 7,
        weightKg: 80,
      ),
      const MonthlySnapshot(
        ym: 202602,
        spentMinor: 20000,
        incomeMinor: 50000,
        topCategoryId: 'expense_food',
        avgMood: 5,
        avgSteps: 8000,
        avgSleep: 8,
      ),
      const MonthlySnapshot(
        ym: 202603,
        spentMinor: 10000,
        incomeMinor: 40000,
        topCategoryId: 'expense_fun',
        avgSteps: 0,
        weightKg: 78,
      ),
    ];

    test('aggregates only the requested year', () {
      final s = builder.build(year: 2026, snapshots: snapshots);
      expect(s.monthsTracked, 3);
      expect(s.incomeMinor, 140000);
      expect(s.spentMinor, 60000);
      expect(s.netMinor, 80000);
    });

    test('picks the most frequent top category', () {
      final s = builder.build(year: 2026, snapshots: snapshots);
      expect(s.topCategoryId, 'expense_food');
    });

    test('estimates total steps and averages logged months', () {
      final s = builder.build(year: 2026, snapshots: snapshots);
      // Jan (31d) 10000 + Feb (28d) 8000; Mar has no steps.
      expect(s.totalSteps, 10000 * 31 + 8000 * 28);
      expect(s.avgSteps, 9000); // mean over the two months that logged steps
    });

    test('mood/sleep average over months that logged them', () {
      final s = builder.build(year: 2026, snapshots: snapshots);
      expect(s.moodMonths, 2);
      expect(s.avgMood, closeTo(4.5, 1e-9));
      expect(s.avgSleep, closeTo(7.5, 1e-9));
    });

    test('weight delta is last minus first logged', () {
      final s = builder.build(year: 2026, snapshots: snapshots);
      expect(s.weightDeltaKg, closeTo(-2, 1e-9));
    });

    test('passes through live headline figures', () {
      final s = builder.build(
        year: 2026,
        snapshots: snapshots,
        lifeScore: 72,
        bestStreak: 21,
        goalsSavedMinor: 150000,
        goalsCompleted: 2,
        percentLived: 33,
      );
      expect(s.lifeScore, 72);
      expect(s.bestStreak, 21);
      expect(s.goalsSavedMinor, 150000);
      expect(s.goalsCompleted, 2);
      expect(s.percentLived, 33);
      expect(s.hasData, isTrue);
    });

    test('no data for the year → hasData false', () {
      final s = builder.build(year: 2030, snapshots: snapshots);
      expect(s.hasData, isFalse);
      expect(s.monthsTracked, 0);
    });
  });
}

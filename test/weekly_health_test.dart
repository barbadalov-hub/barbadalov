import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/health/domain/entities/health_day.dart';
import 'package:lifeos/features/health/domain/weekly_health.dart';

final _now = DateTime(2026, 1, 10, 15); // afternoon of the 10th

HealthDay _day(int dayOfMonth, {int steps = 0, int water = 0, double sleep = 0}) =>
    HealthDay(
      date: DateTime(2026, 1, dayOfMonth),
      steps: steps,
      waterGlasses: water,
      sleepHours: sleep,
    );

void main() {
  group('HealthWeek.summarize', () {
    test('averages the trailing 7 days and counts goal days', () {
      final days = [
        _day(10, steps: 12000, water: 8, sleep: 8), // all goals
        _day(9, steps: 8000, water: 4, sleep: 7),
        _day(8, steps: 10000, water: 8, sleep: 6), // steps + water
      ];
      final s = HealthWeek.summarize(days, _now);
      expect(s.daysLogged, 3);
      expect(s.avgSteps, 10000); // (12000+8000+10000)/3
      expect(s.daysStepGoal, 2); // 12000 and 10000
      expect(s.daysWaterGoal, 2); // two 8-glass days
      expect(s.daysSleepGoal, 1); // only the 8h day
    });

    test('excludes days outside the 7-day window', () {
      final days = [
        _day(10, steps: 10000, water: 8, sleep: 8),
        _day(3, steps: 10000, water: 8, sleep: 8), // 7 days before -> excluded
        _day(2, steps: 10000, water: 8, sleep: 8), // older -> excluded
      ];
      final s = HealthWeek.summarize(days, _now);
      expect(s.daysLogged, 1);
    });

    test('de-duplicates repeated dates, last entry winning', () {
      final days = [
        _day(10, steps: 3000, water: 2, sleep: 5),
        _day(10, steps: 11000, water: 9, sleep: 8), // same day, updated
      ];
      final s = HealthWeek.summarize(days, _now);
      expect(s.daysLogged, 1);
      expect(s.avgSteps, 11000);
      expect(s.daysStepGoal, 1);
    });

    test('an empty week is clean, not a divide-by-zero', () {
      final s = HealthWeek.summarize(const [], _now);
      expect(s.hasData, isFalse);
      expect(s.daysLogged, 0);
      expect(s.avgSteps, 0);
      expect(s.avgSleep, 0);
    });
  });
}

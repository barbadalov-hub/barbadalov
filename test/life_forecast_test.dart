import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/reports/domain/life_forecast.dart';

void main() {
  group('projectWeightKg', () {
    test('a deficit lowers weight over time', () {
      final w = projectWeightKg(currentKg: 90, deficit: 500, days: 90);
      // 500*90/7700 ≈ 5.84 kg lost
      expect(w, lessThan(90));
      expect(w, closeTo(84.16, 0.1));
    });

    test('no deficit keeps weight steady', () {
      expect(projectWeightKg(currentKg: 80, deficit: 0, days: 365), 80);
    });

    test('clamps to a sane human floor', () {
      final w = projectWeightKg(currentKg: 60, deficit: 1000, days: 3650);
      expect(w, 35.0);
    });
  });

  group('daysToWeight', () {
    test('null without a deficit', () {
      expect(daysToWeight(currentKg: 90, targetKg: 80, deficit: 0), isNull);
    });

    test('null when target is above current weight', () {
      expect(daysToWeight(currentKg: 70, targetKg: 80, deficit: 500), isNull);
    });

    test('positive count when the pace can get there', () {
      final d = daysToWeight(currentKg: 90, targetKg: 80, deficit: 500);
      expect(d, isNotNull);
      // 10 kg / (500/7700) ≈ 154 days, ceil'd
      expect(d, 155);
    });
  });

  group('projectSavings', () {
    test('linear accumulation', () {
      expect(projectSavings(monthlyNet: 300, months: 6), 1800);
    });
  });

  group('monthsToSavings', () {
    test('0 when already at goal', () {
      expect(monthsToSavings(monthlyNet: 100, goal: 500, current: 500), 0);
    });

    test('null when not saving', () {
      expect(monthsToSavings(monthlyNet: 0, goal: 500), isNull);
    });

    test('ceils the months needed', () {
      expect(monthsToSavings(monthlyNet: 300, goal: 1000), 4);
    });
  });
}

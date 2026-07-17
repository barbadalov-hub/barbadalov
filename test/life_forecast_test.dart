import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/reports/domain/life_forecast.dart';

void main() {
  group('projectWeightKg', () {
    test('a deficit (negative delta) lowers weight over time', () {
      final w = projectWeightKg(currentKg: 90, dailyDelta: -500, days: 90);
      // 500*90/7700 ≈ 5.84 kg lost
      expect(w, lessThan(90));
      expect(w, closeTo(84.16, 0.1));
    });

    test('a surplus (positive delta) raises weight over time', () {
      final w = projectWeightKg(currentKg: 60, dailyDelta: 300, days: 90);
      // 300*90/7700 ≈ 3.5 kg gained
      expect(w, greaterThan(60));
      expect(w, closeTo(63.5, 0.1));
    });

    test('no delta keeps weight steady', () {
      expect(projectWeightKg(currentKg: 80, dailyDelta: 0, days: 365), 80);
    });

    test('clamps to a sane human floor', () {
      final w = projectWeightKg(currentKg: 60, dailyDelta: -1000, days: 3650);
      expect(w, 35.0);
    });
  });

  group('daysToWeight', () {
    test('null without any delta', () {
      expect(daysToWeight(currentKg: 90, targetKg: 80, dailyDelta: 0), isNull);
    });

    test('null when the pace moves the wrong way', () {
      // Wants to gain to 80 but is in a deficit.
      expect(
          daysToWeight(currentKg: 70, targetKg: 80, dailyDelta: -500), isNull);
      // Wants to lose to 80 but is in a surplus.
      expect(
          daysToWeight(currentKg: 90, targetKg: 80, dailyDelta: 500), isNull);
    });

    test('0 when already at the target', () {
      expect(daysToWeight(currentKg: 80, targetKg: 80, dailyDelta: -500), 0);
    });

    test('positive count losing weight in a deficit', () {
      final d = daysToWeight(currentKg: 90, targetKg: 80, dailyDelta: -500);
      // 10 kg / (500/7700) ≈ 154 days, ceil'd
      expect(d, 155);
    });

    test('positive count gaining weight in a surplus', () {
      final d = daysToWeight(currentKg: 60, targetKg: 65, dailyDelta: 300);
      // 5 kg / (300/7700) ≈ 128.3 days, ceil'd
      expect(d, 129);
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

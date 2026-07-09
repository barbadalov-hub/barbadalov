import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';
import 'package:lifeos/features/profile/domain/fitness_calculator.dart';

void main() {
  const calc = FitnessCalculator();

  group('FitnessCalculator', () {
    test('Mifflin-St Jeor + light activity (desk job, 2 workouts)', () {
      // The exact lifestyle from the spec: desk 10:00–19:00, treadmill ×2/week.
      const p = UserProfile(
        name: 'Test',
        sex: Sex.male,
        age: 30,
        heightCm: 180,
        weightKg: 80,
        deskJob: true,
        workoutsPerWeek: 2,
        goal: FitnessGoal.lose,
      );
      final a = calc.assess(p);

      expect(a.bmr, 1780); // 10*80 + 6.25*180 − 5*30 + 5
      expect(a.tdee, (1780 * 1.375).round()); // light ×1.375
      expect(a.targetKcal, (1780 * 1.375 * 0.85).round()); // −15%, above BMR
      expect(a.proteinG, 144); // 1.8 g/kg on a cut
      expect(a.bmi, closeTo(24.7, 0.1));
      expect(a.bmiKey, 'profile.bmi.normal');
      expect(a.idealWeightKg, closeTo(71.3, 0.2)); // BMI 22 reference
    });

    test('deficit never goes below BMR (no-harm rule)', () {
      const p = UserProfile(
        name: '',
        sex: Sex.female,
        age: 60,
        heightCm: 155,
        weightKg: 48,
        deskJob: true,
        workoutsPerWeek: 0,
        goal: FitnessGoal.lose,
      );
      final a = calc.assess(p);
      expect(a.targetKcal, greaterThanOrEqualTo(a.bmr));
    });

    test('WHR risk flags per WHO thresholds', () {
      const p = UserProfile(
        name: '',
        sex: Sex.female,
        age: 35,
        heightCm: 165,
        weightKg: 70,
        waistCm: 90,
        hipsCm: 100,
      );
      final a = calc.assess(p);
      expect(a.whr, closeTo(0.9, 0.001));
      expect(a.whrHighRisk, isTrue); // > 0.85 for women
    });

    test('US Navy body fat computed only with the needed tape measures', () {
      const withNeck = UserProfile(
        name: '',
        sex: Sex.male,
        age: 30,
        heightCm: 180,
        weightKg: 80,
        waistCm: 85,
        neckCm: 38,
      );
      const withoutNeck = UserProfile(
        name: '',
        sex: Sex.male,
        age: 30,
        heightCm: 180,
        weightKg: 80,
        waistCm: 85,
      );
      final bf = calc.assess(withNeck).bodyFatPct;
      expect(bf, isNotNull);
      expect(bf!, inInclusiveRange(5, 40));
      expect(calc.assess(withoutNeck).bodyFatPct, isNull);
    });
  });
}

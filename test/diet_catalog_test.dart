import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/food/domain/diet_catalog.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';

UserProfile _profile(FitnessGoal goal) => UserProfile(
      name: 'A',
      sex: Sex.male,
      age: 30,
      heightCm: 180,
      weightKg: 82,
      goal: goal,
    );

void main() {
  group('recommendDiets', () {
    test('returns the whole catalog, goal-matching plans first', () {
      final r = recommendDiets(_profile(FitnessGoal.lose));
      expect(r.length, kDietPlans.length);
      // The top plan must suit the goal.
      expect(r.first.goals, contains(FitnessGoal.lose));
    });

    test('muscle gain surfaces the high-protein plan at the top', () {
      final r = recommendDiets(_profile(FitnessGoal.gain));
      expect(r.first.id, 'highProtein');
    });

    test('high waist-hip risk promotes heart-friendly patterns', () {
      final r = recommendDiets(_profile(FitnessGoal.maintain),
          highWhrRisk: true);
      // DASH or Mediterranean should rank ahead of, say, low-carb.
      final dashOrMed = r.indexWhere(
          (d) => d.id == 'dash' || d.id == 'mediterranean');
      final lowCarb = r.indexWhere((d) => d.id == 'lowCarb');
      expect(dashOrMed, lessThan(lowCarb));
    });

    test('ordering is deterministic (stable) for equal scores', () {
      final a = recommendDiets(_profile(FitnessGoal.maintain));
      final b = recommendDiets(_profile(FitnessGoal.maintain));
      expect(a.map((d) => d.id).toList(), b.map((d) => d.id).toList());
    });

    test('every plan exposes three pros and three cons', () {
      for (final plan in kDietPlans) {
        expect(plan.proKeys.length, 3);
        expect(plan.conKeys.length, 3);
        expect(plan.howKey, 'diet.plan.${plan.id}.how');
      }
    });

    test('every plan exposes history, expert and contraindication keys', () {
      for (final plan in kDietPlans) {
        expect(plan.historyKey, 'diet.plan.${plan.id}.history');
        expect(plan.expertKey, 'diet.plan.${plan.id}.expert');
        expect(plan.contraKey, 'diet.plan.${plan.id}.contra');
      }
    });
  });

  group('currentSeasonId', () {
    test('maps months to meteorological seasons', () {
      expect(currentSeasonId(1), 'winter');
      expect(currentSeasonId(12), 'winter');
      expect(currentSeasonId(4), 'spring');
      expect(currentSeasonId(7), 'summer');
      expect(currentSeasonId(10), 'autumn');
    });

    test('every season id has a catalog entry', () {
      final ids = {for (final v in kSeasonalVitamins) v.id};
      for (var m = 1; m <= 12; m++) {
        expect(ids, contains(currentSeasonId(m)));
      }
    });
  });
}

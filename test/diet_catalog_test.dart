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
  });
}

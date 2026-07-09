import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';

/// Everything the dietitian derives from a [UserProfile]. All values are
/// computed with published, peer-reviewed formulas (same set used by
/// open-source fitness libraries like wger / fitness-calc):
///
/// - BMR: Mifflin-St Jeor (most accurate for the general population)
/// - TDEE: BMR × activity multiplier (1.2–1.9)
/// - Target kcal: safe ±10–15% adjustment, never below BMR (no-harm rule)
/// - Protein/fat by g/kg of body weight; carbs fill the remaining calories
/// - WHR risk thresholds per WHO (>0.90 m / >0.85 f)
/// - Body fat: US Navy circumference method (needs neck + waist [+ hips])
class FitnessAssessment extends Equatable {
  final double bmi;
  final String bmiKey; // profile.bmi.<under|normal|over|obese>
  final int bmr;
  final int tdee;
  final int targetKcal;
  final int proteinG;
  final int fatG;
  final int carbsG;
  final double idealWeightKg;
  final double waterLiters;
  final double? whr;
  final bool whrHighRisk;
  final double? bodyFatPct;

  const FitnessAssessment({
    required this.bmi,
    required this.bmiKey,
    required this.bmr,
    required this.tdee,
    required this.targetKcal,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.idealWeightKg,
    required this.waterLiters,
    this.whr,
    this.whrHighRisk = false,
    this.bodyFatPct,
  });

  @override
  List<Object?> get props => [
        bmi, bmiKey, bmr, tdee, targetKcal, proteinG, fatG, carbsG,
        idealWeightKg, waterLiters, whr, whrHighRisk, bodyFatPct, //
      ];
}

class FitnessCalculator {
  const FitnessCalculator();

  FitnessAssessment assess(UserProfile p) {
    final heightM = p.heightCm / 100;
    final bmi = p.weightKg / (heightM * heightM);

    // Mifflin-St Jeor.
    final bmr = 10 * p.weightKg +
        6.25 * p.heightCm -
        5 * p.age +
        (p.sex == Sex.male ? 5 : -161);

    final tdee = bmr * _activityMultiplier(p);

    // Safe target: 15% deficit to lose, 10% surplus to gain — and never below
    // BMR, so the plan cannot recommend an unhealthy crash diet.
    final rawTarget = switch (p.goal) {
      FitnessGoal.lose => tdee * 0.85,
      FitnessGoal.maintain => tdee,
      FitnessGoal.gain => tdee * 1.10,
    };
    final targetKcal = math.max(rawTarget, bmr).round();

    // Macros: protein per kg by goal, fat 0.9 g/kg (min 50 g), carbs = rest.
    final proteinPerKg = switch (p.goal) {
      FitnessGoal.lose => 1.8,
      FitnessGoal.maintain => 1.6,
      FitnessGoal.gain => 2.0,
    };
    final proteinG = (proteinPerKg * p.weightKg).round();
    final fatG = math.max(0.9 * p.weightKg, 50).round();
    final carbsKcal = targetKcal - proteinG * 4 - fatG * 9;
    final carbsG = math.max(carbsKcal / 4, 0).round();

    // Waist-hip ratio + WHO risk flag.
    double? whr;
    var whrHighRisk = false;
    if (p.waistCm != null && p.hipsCm != null && p.hipsCm! > 0) {
      whr = p.waistCm! / p.hipsCm!;
      whrHighRisk = p.sex == Sex.male ? whr > 0.90 : whr > 0.85;
    }

    return FitnessAssessment(
      bmi: bmi,
      bmiKey: _bmiKey(bmi),
      bmr: bmr.round(),
      tdee: tdee.round(),
      targetKcal: targetKcal,
      proteinG: proteinG,
      fatG: fatG,
      carbsG: carbsG,
      idealWeightKg: 22 * heightM * heightM, // BMI-22 reference weight
      waterLiters: 0.033 * p.weightKg,
      whr: whr,
      whrHighRisk: whrHighRisk,
      bodyFatPct: _navyBodyFat(p),
    );
  }

  /// Activity multiplier from lifestyle: a desk job contributes nothing, an
  /// on-your-feet job counts like two extra sessions, then each workout per
  /// week pushes the score up. Example from the spec — desk 10:00–19:00 plus
  /// treadmill twice a week → "light" (×1.375).
  double _activityMultiplier(UserProfile p) {
    final score = p.workoutsPerWeek + (p.deskJob ? 0 : 2);
    if (score <= 1) return 1.2;
    if (score <= 3) return 1.375;
    if (score <= 5) return 1.55;
    if (score <= 7) return 1.725;
    return 1.9;
  }

  String _bmiKey(double bmi) {
    if (bmi < 18.5) return 'profile.bmi.under';
    if (bmi < 25) return 'profile.bmi.normal';
    if (bmi < 30) return 'profile.bmi.over';
    return 'profile.bmi.obese';
  }

  /// US Navy circumference method. Returns null when the needed tape
  /// measurements are missing.
  double? _navyBodyFat(UserProfile p) {
    final waist = p.waistCm;
    final neck = p.neckCm;
    if (waist == null || neck == null) return null;

    double log10(double x) => math.log(x) / math.ln10;

    double pct;
    if (p.sex == Sex.male) {
      if (waist <= neck) return null;
      pct = 495 /
              (1.0324 -
                  0.19077 * log10(waist - neck) +
                  0.15456 * log10(p.heightCm)) -
          450;
    } else {
      final hips = p.hipsCm;
      if (hips == null || waist + hips <= neck) return null;
      pct = 495 /
              (1.29579 -
                  0.35004 * log10(waist + hips - neck) +
                  0.22100 * log10(p.heightCm)) -
          450;
    }
    return pct.clamp(3.0, 60.0).toDouble();
  }
}

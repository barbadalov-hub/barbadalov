/// Simple, honest forward projections for the "what will happen if…" simulator.
/// Straight-line models on purpose — they answer "at this pace, roughly when?"
/// which is what motivates behaviour change. Pure — unit-tested.
library;

/// About 7700 kcal per kilogram of body weight.
const double kcalPerKg = 7700;

/// Projected weight after [days] at a daily calorie [deficit] (kcal below
/// maintenance; a deficit lowers weight). Clamped to a sane human range.
double projectWeightKg({
  required double currentKg,
  required int deficit,
  required int days,
}) {
  final kg = currentKg - (deficit * days) / kcalPerKg;
  return kg.clamp(35.0, 400.0);
}

/// Days to reach [targetKg] from [currentKg] at a daily [deficit]. Null when
/// the pace can't get there (no deficit, or target is above current weight
/// while in a deficit).
int? daysToWeight({
  required double currentKg,
  required double targetKg,
  required int deficit,
}) {
  if (deficit <= 0) return null;
  final toLose = currentKg - targetKg; // positive when we need to lose
  if (toLose <= 0) return null;
  final perDay = deficit / kcalPerKg;
  return (toLose / perDay).ceil();
}

/// Savings accumulated after [months] at a [monthlyNet] rate.
double projectSavings({required double monthlyNet, required int months}) =>
    monthlyNet * months;

/// Months to save [goal] (from [current]) at [monthlyNet]. Null when not
/// saving (net ≤ 0); 0 when already there.
int? monthsToSavings({
  required double monthlyNet,
  required double goal,
  double current = 0,
}) {
  if (goal - current <= 0) return 0;
  if (monthlyNet <= 0) return null;
  return ((goal - current) / monthlyNet).ceil();
}

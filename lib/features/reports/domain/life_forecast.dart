/// Simple, honest forward projections for the "what will happen if…" simulator.
/// Straight-line models on purpose — they answer "at this pace, roughly when?"
/// which is what motivates behaviour change. Pure — unit-tested.
library;

/// About 7700 kcal per kilogram of body weight.
const double kcalPerKg = 7700;

/// Projected weight after [days] given a daily calorie [dailyDelta]:
/// negative = deficit (weight falls), positive = surplus (weight rises).
/// Clamped to a sane human range.
double projectWeightKg({
  required double currentKg,
  required int dailyDelta,
  required int days,
}) {
  final kg = currentKg + (dailyDelta * days) / kcalPerKg;
  return kg.clamp(35.0, 400.0);
}

/// Days to move from [currentKg] to [targetKg] at a daily calorie [dailyDelta]
/// (negative = deficit → lose, positive = surplus → gain). Returns 0 when
/// already there, and null when the pace moves the wrong way (or not at all)
/// relative to the target.
int? daysToWeight({
  required double currentKg,
  required double targetKg,
  required int dailyDelta,
}) {
  final diff = targetKg - currentKg; // + need to gain, − need to lose
  if (diff.abs() < 0.05) return 0;
  if (dailyDelta == 0) return null;
  final perDay = dailyDelta / kcalPerKg; // + gains weight, − loses weight
  if (diff.isNegative != perDay.isNegative) return null; // wrong direction
  return (diff / perDay).ceil();
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

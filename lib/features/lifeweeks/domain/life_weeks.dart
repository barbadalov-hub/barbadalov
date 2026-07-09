/// "Your life in weeks" — the signature LifeOS visualization. Turns an age into
/// a finite grid of weeks so the scale of a life is tangible. Pure math.
class LifeWeeks {
  final int ageYears;
  final int lifeExpectancy;

  const LifeWeeks({required this.ageYears, this.lifeExpectancy = 90});

  /// ~52.14 weeks per year; a whole life is `lifeExpectancy` rows of 52.
  int get weeksPerYear => 52;
  int get totalWeeks => lifeExpectancy * weeksPerYear;
  int get weeksLived =>
      (ageYears * 52.1429).round().clamp(0, totalWeeks).toInt();
  int get weeksLeft => (totalWeeks - weeksLived).clamp(0, totalWeeks).toInt();
  double get fractionLived => totalWeeks == 0 ? 0 : weeksLived / totalWeeks;
  int get percentLived => (fractionLived * 100).round();
  int get yearsLeft => (lifeExpectancy - ageYears).clamp(0, lifeExpectancy);
}

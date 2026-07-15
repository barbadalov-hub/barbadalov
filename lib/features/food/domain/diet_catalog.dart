import 'package:lifeos/features/profile/domain/entities/user_profile.dart';

/// A popular, doctor-recognised eating pattern with plain-language guidance.
///
/// Content is **educational**, not medical advice — the text lives in the i18n
/// table under `diet.plan.<id>.*`. Each plan declares which fitness goals it
/// tends to suit so the recommender can rank them for a given profile.
class DietPlan {
  final String id;
  final String emoji;
  final Set<FitnessGoal> goals;

  const DietPlan(this.id, this.emoji, this.goals);

  String get nameKey => 'diet.plan.$id.name';
  String get summaryKey => 'diet.plan.$id.summary';
  String get tipsKey => 'diet.plan.$id.tips';

  /// A longer "how it works" breakdown.
  String get howKey => 'diet.plan.$id.how';

  /// Origin / who devised it.
  String get historyKey => 'diet.plan.$id.history';

  /// What leading doctors / dietitians say about it.
  String get expertKey => 'diet.plan.$id.expert';

  /// Who should avoid it or use it only under medical supervision
  /// (e.g. gastritis, ulcer, kidney disease, pregnancy).
  String get contraKey => 'diet.plan.$id.contra';

  /// Three upsides and three downsides (i18n keys).
  List<String> get proKeys =>
      ['diet.plan.$id.pro1', 'diet.plan.$id.pro2', 'diet.plan.$id.pro3'];
  List<String> get conKeys =>
      ['diet.plan.$id.con1', 'diet.plan.$id.con2', 'diet.plan.$id.con3'];
}

/// General, seasonal vitamin guidance — educational, not a prescription.
/// Shown alongside the diets so the user knows what tends to run low when.
class SeasonalVitamins {
  final String id; // winter | spring | summer | autumn
  final String emoji;
  const SeasonalVitamins(this.id, this.emoji);

  String get nameKey => 'vit.$id.name';
  String get bodyKey => 'vit.$id.body';
}

const kSeasonalVitamins = <SeasonalVitamins>[
  SeasonalVitamins('winter', '❄️'),
  SeasonalVitamins('spring', '🌱'),
  SeasonalVitamins('summer', '☀️'),
  SeasonalVitamins('autumn', '🍂'),
];

/// Meteorological season id for a month (northern hemisphere).
String currentSeasonId(int month) {
  if (month == 12 || month <= 2) return 'winter';
  if (month <= 5) return 'spring';
  if (month <= 8) return 'summer';
  return 'autumn';
}

/// The built-in catalog of well-known diets. Kept deliberately mainstream and
/// safe — patterns endorsed by dietitians (Mediterranean, DASH, balanced
/// plate, higher-protein, moderate low-carb, 16:8 time-restricted eating).
const kDietPlans = <DietPlan>[
  DietPlan('mediterranean', '🫒', {FitnessGoal.lose, FitnessGoal.maintain}),
  DietPlan('dash', '🥗', {FitnessGoal.lose, FitnessGoal.maintain}),
  DietPlan('balanced', '🍽️',
      {FitnessGoal.lose, FitnessGoal.maintain, FitnessGoal.gain}),
  DietPlan('highProtein', '🍗',
      {FitnessGoal.gain, FitnessGoal.maintain, FitnessGoal.lose}),
  DietPlan('lowCarb', '🥑', {FitnessGoal.lose}),
  DietPlan('fasting', '⏱️', {FitnessGoal.lose, FitnessGoal.maintain}),
];

/// Ranks the catalog for a profile: plans matching the user's goal come first,
/// with a few health-aware bumps (heart-friendly patterns for a high
/// waist-hip ratio, protein-forward for muscle gain). Pure — unit-tested.
List<DietPlan> recommendDiets(UserProfile p, {bool highWhrRisk = false}) {
  int score(DietPlan d) {
    var s = d.goals.contains(p.goal) ? 3 : 0;
    if (highWhrRisk && (d.id == 'dash' || d.id == 'mediterranean')) s += 2;
    if (p.goal == FitnessGoal.lose &&
        (d.id == 'mediterranean' || d.id == 'balanced')) {
      s += 1;
    }
    if (p.goal == FitnessGoal.gain && d.id == 'highProtein') s += 2;
    return s;
  }

  final indexed = [
    for (var i = 0; i < kDietPlans.length; i++) (i, kDietPlans[i]),
  ]..sort((a, b) {
      final byScore = score(b.$2).compareTo(score(a.$2));
      return byScore != 0 ? byScore : a.$1.compareTo(b.$1); // stable
    });
  return [for (final e in indexed) e.$2];
}

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

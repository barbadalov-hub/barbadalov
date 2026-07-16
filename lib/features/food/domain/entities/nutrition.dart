import 'package:equatable/equatable.dart';

enum MealSlot { breakfast, lunch, dinner, snack }

enum PortionUnit { g, ml, pcs }

/// Calories + macros for one serving (data model inspired by the Open Food
/// Facts "nutriments" shape, simplified to what the planner needs).
class NutritionFacts extends Equatable {
  final int kcal;
  final int proteinG;
  final int fatG;
  final int carbsG;

  const NutritionFacts({
    required this.kcal,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
  });

  static const zero =
      NutritionFacts(kcal: 0, proteinG: 0, fatG: 0, carbsG: 0);

  NutritionFacts operator +(NutritionFacts other) => NutritionFacts(
        kcal: kcal + other.kcal,
        proteinG: proteinG + other.proteinG,
        fatG: fatG + other.fatG,
        carbsG: carbsG + other.carbsG,
      );

  @override
  List<Object?> get props => [kcal, proteinG, fatG, carbsG];
}

/// One ingredient of a meal: a product reference + the portion used.
class IngredientPortion extends Equatable {
  final String productId;
  final int amount;
  final PortionUnit unit;

  const IngredientPortion(this.productId, this.amount, this.unit);

  @override
  List<Object?> get props => [productId, amount, unit];
}

/// A dish the dietitian can put on the plan. [nameKey] is an i18n key so dish
/// names follow the app language.
class MealOption extends Equatable {
  final String id;
  final MealSlot slot;
  final String emoji;
  final String nameKey;
  final List<IngredientPortion> ingredients;
  final NutritionFacts nutrition;

  /// Optional cuisine/country i18n key (e.g. `region.italy`) for dishes from a
  /// particular national cuisine; null for everyday local food.
  final String? region;

  const MealOption({
    required this.id,
    required this.slot,
    required this.emoji,
    required this.nameKey,
    required this.ingredients,
    required this.nutrition,
    this.region,
  });

  /// Scale the portion by [factor] (nutrition + gram/ml amounts, rounded to
  /// 5 g/ml; piece counts stay whole). Used by the planner to land closer to
  /// the calorie target — the approach diet apps take instead of fixed plates.
  MealOption scaled(double factor) {
    if ((factor - 1).abs() < 0.01) return this;
    int roundTo5(num v) => (v / 5).round() * 5;
    return MealOption(
      id: id,
      slot: slot,
      emoji: emoji,
      nameKey: nameKey,
      region: region,
      ingredients: [
        for (final i in ingredients)
          i.unit == PortionUnit.pcs
              ? i
              : IngredientPortion(
                  i.productId,
                  roundTo5(i.amount * factor).clamp(5, 100000).toInt(),
                  i.unit,
                ),
      ],
      nutrition: NutritionFacts(
        kcal: (nutrition.kcal * factor).round(),
        proteinG: (nutrition.proteinG * factor).round(),
        fatG: (nutrition.fatG * factor).round(),
        carbsG: (nutrition.carbsG * factor).round(),
      ),
    );
  }

  @override
  List<Object?> get props =>
      [id, slot, emoji, nameKey, ingredients, nutrition, region];
}

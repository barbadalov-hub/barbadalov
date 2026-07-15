import 'package:lifeos/features/food/domain/entities/nutrition.dart';

/// The dietitian's dish catalog — Ukrainian home-cooking staples with realistic
/// per-serving nutrition. A later phase can replace/extend this with an Open
/// Food Facts–backed source; the planner only sees `List<MealOption>`.
class MealCatalog {
  const MealCatalog._();

  static const breakfasts = <MealOption>[
    MealOption(
      id: 'casserole',
      slot: MealSlot.breakfast,
      emoji: '🥧',
      nameKey: 'meal.casserole',
      ingredients: [
        IngredientPortion('cottage_cheese', 300, PortionUnit.g),
        IngredientPortion('eggs', 2, PortionUnit.pcs),
        IngredientPortion('flour', 30, PortionUnit.g),
        IngredientPortion('honey', 20, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 430, proteinG: 38, fatG: 16, carbsG: 30),
    ),
    MealOption(
      id: 'oatmeal',
      slot: MealSlot.breakfast,
      emoji: '🥣',
      nameKey: 'meal.oatmeal',
      ingredients: [
        IngredientPortion('oats', 60, PortionUnit.g),
        IngredientPortion('milk', 250, PortionUnit.ml),
        IngredientPortion('banana', 1, PortionUnit.pcs),
        IngredientPortion('walnuts', 15, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 390, proteinG: 14, fatG: 12, carbsG: 56),
    ),
    MealOption(
      id: 'syrnyky',
      slot: MealSlot.breakfast,
      emoji: '🥞',
      nameKey: 'meal.syrnyky',
      ingredients: [
        IngredientPortion('cottage_cheese', 250, PortionUnit.g),
        IngredientPortion('eggs', 1, PortionUnit.pcs),
        IngredientPortion('flour', 40, PortionUnit.g),
        IngredientPortion('honey', 15, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 420, proteinG: 32, fatG: 18, carbsG: 32),
    ),
    MealOption(
      id: 'omelette',
      slot: MealSlot.breakfast,
      emoji: '🍳',
      nameKey: 'meal.omelette',
      ingredients: [
        IngredientPortion('eggs', 3, PortionUnit.pcs),
        IngredientPortion('milk', 50, PortionUnit.ml),
        IngredientPortion('tomatoes', 100, PortionUnit.g),
        IngredientPortion('cheese', 30, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 360, proteinG: 25, fatG: 24, carbsG: 8),
    ),
    MealOption(
      id: 'protein_pancakes',
      slot: MealSlot.breakfast,
      emoji: '🥞',
      nameKey: 'meal.protein_pancakes',
      ingredients: [
        IngredientPortion('oats', 50, PortionUnit.g),
        IngredientPortion('eggs', 2, PortionUnit.pcs),
        IngredientPortion('banana', 1, PortionUnit.pcs),
        IngredientPortion('cottage_cheese', 100, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 430, proteinG: 30, fatG: 13, carbsG: 48),
    ),
    MealOption(
      id: 'veggie_scramble',
      slot: MealSlot.breakfast,
      emoji: '🍳',
      nameKey: 'meal.veggie_scramble',
      ingredients: [
        IngredientPortion('eggs', 3, PortionUnit.pcs),
        IngredientPortion('tomatoes', 100, PortionUnit.g),
        IngredientPortion('cheese', 30, PortionUnit.g),
        IngredientPortion('onion', 30, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 340, proteinG: 24, fatG: 23, carbsG: 9),
    ),
  ];

  static const lunches = <MealOption>[
    MealOption(
      id: 'borscht',
      slot: MealSlot.lunch,
      emoji: '🍲',
      nameKey: 'meal.borscht',
      ingredients: [
        IngredientPortion('beef', 120, PortionUnit.g),
        IngredientPortion('beets', 150, PortionUnit.g),
        IngredientPortion('potatoes', 150, PortionUnit.g),
        IngredientPortion('carrots', 50, PortionUnit.g),
        IngredientPortion('onion', 50, PortionUnit.g),
        IngredientPortion('bread', 2, PortionUnit.pcs),
      ],
      nutrition: NutritionFacts(kcal: 520, proteinG: 34, fatG: 18, carbsG: 52),
    ),
    MealOption(
      id: 'buckwheat_chicken',
      slot: MealSlot.lunch,
      emoji: '🍗',
      nameKey: 'meal.buckwheat_chicken',
      ingredients: [
        IngredientPortion('chicken', 180, PortionUnit.g),
        IngredientPortion('buckwheat', 80, PortionUnit.g),
        IngredientPortion('carrots', 80, PortionUnit.g),
        IngredientPortion('onion', 50, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 550, proteinG: 45, fatG: 12, carbsG: 60),
    ),
    MealOption(
      id: 'rice_fish',
      slot: MealSlot.lunch,
      emoji: '🐟',
      nameKey: 'meal.rice_fish',
      ingredients: [
        IngredientPortion('fish', 200, PortionUnit.g),
        IngredientPortion('rice', 80, PortionUnit.g),
        IngredientPortion('cucumbers', 100, PortionUnit.g),
        IngredientPortion('tomatoes', 100, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 500, proteinG: 38, fatG: 10, carbsG: 62),
    ),
    MealOption(
      id: 'chicken_pasta',
      slot: MealSlot.lunch,
      emoji: '🍗',
      nameKey: 'meal.chicken_pasta',
      ingredients: [
        IngredientPortion('chicken', 150, PortionUnit.g),
        IngredientPortion('pasta', 80, PortionUnit.g),
        IngredientPortion('tomatoes', 100, PortionUnit.g),
        IngredientPortion('cheese', 20, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 560, proteinG: 45, fatG: 14, carbsG: 62),
    ),
    MealOption(
      id: 'lentil_soup',
      slot: MealSlot.lunch,
      emoji: '🍲',
      nameKey: 'meal.lentil_soup',
      ingredients: [
        IngredientPortion('lentils', 90, PortionUnit.g),
        IngredientPortion('carrots', 60, PortionUnit.g),
        IngredientPortion('onion', 50, PortionUnit.g),
        IngredientPortion('potatoes', 100, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 420, proteinG: 24, fatG: 4, carbsG: 74),
    ),
  ];

  static const dinners = <MealOption>[
    MealOption(
      id: 'baked_chicken',
      slot: MealSlot.dinner,
      emoji: '🥗',
      nameKey: 'meal.baked_chicken',
      ingredients: [
        IngredientPortion('chicken', 200, PortionUnit.g),
        IngredientPortion('tomatoes', 150, PortionUnit.g),
        IngredientPortion('cucumbers', 150, PortionUnit.g),
        IngredientPortion('cheese', 20, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 430, proteinG: 42, fatG: 16, carbsG: 24),
    ),
    MealOption(
      id: 'stewed_fish',
      slot: MealSlot.dinner,
      emoji: '🐠',
      nameKey: 'meal.stewed_fish',
      ingredients: [
        IngredientPortion('fish', 220, PortionUnit.g),
        IngredientPortion('carrots', 100, PortionUnit.g),
        IngredientPortion('onion', 70, PortionUnit.g),
        IngredientPortion('potatoes', 150, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 400, proteinG: 36, fatG: 14, carbsG: 28),
    ),
    MealOption(
      id: 'cottage_bowl',
      slot: MealSlot.dinner,
      emoji: '🥙',
      nameKey: 'meal.cottage_bowl',
      ingredients: [
        IngredientPortion('cottage_cheese', 200, PortionUnit.g),
        IngredientPortion('cucumbers', 150, PortionUnit.g),
        IngredientPortion('tomatoes', 100, PortionUnit.g),
        IngredientPortion('walnuts', 10, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 330, proteinG: 30, fatG: 12, carbsG: 22),
    ),
    MealOption(
      id: 'beef_veg',
      slot: MealSlot.dinner,
      emoji: '🥗',
      nameKey: 'meal.beef_veg',
      ingredients: [
        IngredientPortion('beef', 150, PortionUnit.g),
        IngredientPortion('carrots', 80, PortionUnit.g),
        IngredientPortion('onion', 50, PortionUnit.g),
        IngredientPortion('tomatoes', 100, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 430, proteinG: 38, fatG: 22, carbsG: 18),
    ),
    MealOption(
      id: 'shrimp_salad',
      slot: MealSlot.dinner,
      emoji: '🐟',
      nameKey: 'meal.shrimp_salad',
      ingredients: [
        IngredientPortion('shrimp', 150, PortionUnit.g),
        IngredientPortion('cucumbers', 150, PortionUnit.g),
        IngredientPortion('tomatoes', 100, PortionUnit.g),
        IngredientPortion('cheese', 20, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 300, proteinG: 32, fatG: 12, carbsG: 12),
    ),
  ];

  static const snacks = <MealOption>[
    MealOption(
      id: 'yogurt_nuts',
      slot: MealSlot.snack,
      emoji: '🥛',
      nameKey: 'meal.yogurt_nuts',
      ingredients: [
        IngredientPortion('yogurt', 300, PortionUnit.g),
        IngredientPortion('walnuts', 15, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 220, proteinG: 10, fatG: 12, carbsG: 16),
    ),
    MealOption(
      id: 'apple_cheese',
      slot: MealSlot.snack,
      emoji: '🍎',
      nameKey: 'meal.apple_cheese',
      ingredients: [
        IngredientPortion('apple', 1, PortionUnit.pcs),
        IngredientPortion('cheese', 30, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 180, proteinG: 8, fatG: 8, carbsG: 18),
    ),
    MealOption(
      id: 'banana_snack',
      slot: MealSlot.snack,
      emoji: '🍌',
      nameKey: 'meal.banana_snack',
      ingredients: [
        IngredientPortion('banana', 1, PortionUnit.pcs),
      ],
      nutrition: NutritionFacts(kcal: 105, proteinG: 1, fatG: 0, carbsG: 27),
    ),
    MealOption(
      id: 'cottage_berries',
      slot: MealSlot.snack,
      emoji: '🥣',
      nameKey: 'meal.cottage_berries',
      ingredients: [
        IngredientPortion('cottage_cheese', 150, PortionUnit.g),
        IngredientPortion('berries', 80, PortionUnit.g),
      ],
      nutrition: NutritionFacts(kcal: 200, proteinG: 22, fatG: 6, carbsG: 16),
    ),
    MealOption(
      id: 'kefir_snack',
      slot: MealSlot.snack,
      emoji: '🥛',
      nameKey: 'meal.kefir_snack',
      ingredients: [
        IngredientPortion('kefir', 300, PortionUnit.ml),
      ],
      nutrition: NutritionFacts(kcal: 150, proteinG: 9, fatG: 6, carbsG: 15),
    ),
  ];

  static const all = <MealOption>[
    ...breakfasts,
    ...lunches,
    ...dinners,
    ...snacks,
  ];
}

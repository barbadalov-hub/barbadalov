import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/food/data/meal_catalog.dart';
import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/domain/pantry_week_planner.dart';

MealOption _meal(String id, MealSlot slot, List<String> productIds) =>
    MealOption(
      id: id,
      slot: slot,
      emoji: '🍲',
      nameKey: 'meal.$id',
      ingredients: [
        for (final p in productIds) IngredientPortion(p, 100, PortionUnit.g),
      ],
      nutrition:
          const NutritionFacts(kcal: 300, proteinG: 15, fatG: 8, carbsG: 30),
    );

void main() {
  const planner = PantryWeekPlanner();

  test('builds the requested number of days', () {
    final week = planner.plan(
      available: {'eggs', 'oats'},
      meals: [
        _meal('b', MealSlot.breakfast, ['eggs', 'oats']),
      ],
      days: 7,
    );
    expect(week.length, 7);
  });

  test('varies dishes across days when several are available', () {
    final week = planner.plan(
      available: {'eggs', 'oats', 'milk'},
      meals: [
        _meal('b1', MealSlot.breakfast, ['eggs']),
        _meal('b2', MealSlot.breakfast, ['oats']),
        _meal('b3', MealSlot.breakfast, ['milk']),
      ],
      days: 3,
    );
    final chosen = week.map((d) => d.breakfast!.meal.id).toList();
    expect(chosen.toSet().length, 3); // three distinct breakfasts
  });

  test('puts a use-it-up dish on the first day', () {
    final week = planner.plan(
      available: {'eggs', 'oats', 'milk'},
      expiring: {'milk'},
      meals: [
        _meal('plain', MealSlot.breakfast, ['eggs', 'oats']),
        _meal('useup', MealSlot.breakfast, ['milk']),
      ],
      days: 2,
    );
    expect(week.first.breakfast!.meal.id, 'useup');
    expect(week.first.breakfast!.usesExpiring, isTrue);
  });

  test('leaves a slot empty when no dish exists for it', () {
    final week = planner.plan(
      available: {'eggs'},
      meals: [_meal('b', MealSlot.breakfast, ['eggs'])],
      days: 1,
    );
    expect(week.first.breakfast, isNotNull);
    expect(week.first.lunch, isNull);
    expect(week.first.dinner, isNull);
  });

  test('day kcal sums the planned dishes', () {
    final week = planner.plan(
      available: {'eggs', 'rice', 'chicken'},
      meals: [
        _meal('b', MealSlot.breakfast, ['eggs']),
        _meal('l', MealSlot.lunch, ['rice']),
        _meal('d', MealSlot.dinner, ['chicken']),
      ],
      days: 1,
    );
    expect(week.first.kcal, 900); // 3 × 300
    expect(week.first.meals.length, 3);
  });

  test('runs over the real catalog', () {
    final week = planner.plan(
      available: {'eggs', 'oats', 'milk', 'chicken', 'rice', 'tomatoes'},
      meals: MealCatalog.all,
    );
    expect(week.length, 7);
  });
}

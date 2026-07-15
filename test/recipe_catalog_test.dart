import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/food/data/meal_catalog.dart';
import 'package:lifeos/features/food/domain/recipe_catalog.dart';

void main() {
  group('recipe catalog', () {
    test('every catalog dish has a recipe with at least one method', () {
      for (final meal in MealCatalog.all) {
        final recipe = recipeFor(meal.id);
        expect(recipe, isNotNull, reason: 'no recipe for ${meal.id}');
        expect(recipe!.methods, isNotEmpty);
      }
    });

    test('step and flavor keys follow the recipe.<meal>.<method> pattern', () {
      final r = recipeFor('baked_chicken')!;
      expect(r.methods.map((m) => m.id), containsAll(['oven', 'grill']));
      expect(r.stepsKey('oven'), 'recipe.baked_chicken.oven');
      expect(r.flavorKey, 'recipe.baked_chicken.flavor');
    });

    test('unknown dish has no recipe', () {
      expect(recipeFor('does_not_exist'), isNull);
    });
  });
}

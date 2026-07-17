import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/food/data/meal_catalog.dart';
import 'package:lifeos/features/food/domain/cook_from_pantry.dart';
import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/domain/shelf_life_catalog.dart';

MealOption _meal(String id, List<String> productIds) => MealOption(
      id: id,
      slot: MealSlot.lunch,
      emoji: '🍲',
      nameKey: 'meal.$id',
      ingredients: [
        for (final p in productIds) IngredientPortion(p, 100, PortionUnit.g),
      ],
      nutrition: const NutritionFacts(kcal: 400, proteinG: 20, fatG: 10, carbsG: 40),
    );

void main() {
  const engine = CookFromPantry();

  test('empty pantry suggests nothing', () {
    expect(engine.suggest(available: const {}, meals: [_meal('a', ['eggs'])]),
        isEmpty);
  });

  test('only meals above the coverage threshold are suggested', () {
    final meals = [
      _meal('full', ['eggs', 'bread']), // 2/2 = 100%
      _meal('half', ['eggs', 'milk', 'cheese', 'rice']), // 1/4 = 25%
    ];
    final r = engine.suggest(available: {'eggs', 'bread'}, meals: meals);
    expect(r.map((p) => p.meal.id), ['full']);
    expect(r.single.matched, 2);
    expect(r.single.missingProductIds, isEmpty);
  });

  test('reports the missing ingredients', () {
    final r = engine.suggest(
      available: {'eggs', 'bread', 'cheese'},
      meals: [_meal('omelette', ['eggs', 'bread', 'cheese', 'milk'])],
    );
    expect(r.single.matched, 3);
    expect(r.single.total, 4);
    expect(r.single.missingProductIds, ['milk']);
  });

  test('meals using an expiring item are surfaced first', () {
    final meals = [
      _meal('plain', ['rice', 'chicken']), // full coverage, no expiring
      _meal('useup', ['eggs', 'milk']), // full coverage, uses expiring milk
    ];
    final r = engine.suggest(
      available: {'rice', 'chicken', 'eggs', 'milk'},
      expiring: {'milk'},
      meals: meals,
    );
    expect(r.first.meal.id, 'useup');
    expect(r.first.usesExpiring, isTrue);
  });

  test('respects the limit', () {
    final meals = [for (var i = 0; i < 10; i++) _meal('m$i', ['eggs'])];
    final r = engine.suggest(available: {'eggs'}, meals: meals, limit: 3);
    expect(r.length, 3);
  });

  test('runs over the real catalog without error and matches by product id',
      () {
    final r = engine.suggest(
      available: {'eggs', 'oats', 'milk', 'banana', 'honey'},
      meals: MealCatalog.all,
    );
    // Every suggestion must actually meet the coverage bar.
    for (final pm in r) {
      expect(pm.coverage, greaterThanOrEqualTo(CookFromPantry.minCoverage));
    }
  });

  group('bestUsing', () {
    test('picks the best-covered dish that uses the product', () {
      final meals = [
        _meal('toast', ['bread', 'butter', 'jam', 'cheese']), // 1/4, low
        _meal('sandwich', ['bread', 'cheese']), // 2/2 uses bread
        _meal('salad', ['tomatoes', 'cucumbers']), // doesn't use bread
      ];
      final best = engine.bestUsing(
        productId: 'bread',
        available: {'bread', 'cheese'},
        meals: meals,
      );
      expect(best, isNotNull);
      expect(best!.meal.id, 'sandwich');
    });

    test('null when no dish using the product meets coverage', () {
      final best = engine.bestUsing(
        productId: 'bread',
        available: {'bread'},
        meals: [_meal('feast', ['bread', 'a', 'b', 'c', 'd'])], // 1/5
      );
      expect(best, isNull);
    });

    test('null when nothing uses the product at all', () {
      final best = engine.bestUsing(
        productId: 'bread',
        available: {'eggs'},
        meals: [_meal('omelette', ['eggs'])],
      );
      expect(best, isNull);
    });
  });

  group('shelf-life catalog', () {
    test('known products carry a positive shelf life', () {
      for (final p in kKnownProducts) {
        expect(p.shelfLifeDays, greaterThan(0), reason: p.id);
        expect(p.emoji, isNotEmpty, reason: p.id);
      }
    });

    test('ids are unique', () {
      final ids = kKnownProducts.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('lookup helpers resolve and default to null', () {
      expect(knownProduct('bread')?.shelfLifeDays, 5);
      expect(shelfLifeDays('bread'), 5);
      expect(knownProduct('unobtanium'), isNull);
      expect(shelfLifeDays('unobtanium'), isNull);
    });
  });
}

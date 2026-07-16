import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/food/data/meal_catalog.dart';
import 'package:lifeos/features/food/data/ua_store_price_catalog.dart';
import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/domain/weekly_groceries.dart';

void main() {
  const planner = WeeklyGroceryPlanner(UaStorePriceCatalog());

  test('aggregates the same product across meals into whole packs', () {
    // Two meals both using eggs: 2 pcs + 3 pcs = 5 pcs → one 10-pack.
    const a = MealOption(
      id: 'a',
      slot: MealSlot.breakfast,
      emoji: '🍳',
      nameKey: 'x',
      ingredients: [IngredientPortion('eggs', 2, PortionUnit.pcs)],
      nutrition: NutritionFacts(kcal: 100, proteinG: 1, fatG: 1, carbsG: 1),
    );
    const b = MealOption(
      id: 'b',
      slot: MealSlot.breakfast,
      emoji: '🍳',
      nameKey: 'x',
      ingredients: [IngredientPortion('eggs', 3, PortionUnit.pcs)],
      nutrition: NutritionFacts(kcal: 100, proteinG: 1, fatG: 1, carbsG: 1),
    );

    final g = planner.build([a, b]);
    final eggs = g.lines.singleWhere((l) => l.productId == 'eggs');
    expect(eggs.totalAmount, 5);
    expect(eggs.packs, 1); // 5 ≤ one 10-pack
    // The cheapest store's egg pack is store 1 in the seeded catalog.
    expect(eggs.store.id, 's1');
  });

  test('needs more packs when the amount exceeds one pack', () {
    // 12 eggs → two 10-packs.
    const twelveEggs = MealOption(
      id: 'm',
      slot: MealSlot.breakfast,
      emoji: '🍳',
      nameKey: 'x',
      ingredients: [IngredientPortion('eggs', 12, PortionUnit.pcs)],
      nutrition: NutritionFacts(kcal: 100, proteinG: 1, fatG: 1, carbsG: 1),
    );
    final eggs =
        planner.build([twelveEggs]).lines.singleWhere((l) => l.productId == 'eggs');
    expect(eggs.packs, 2);
  });

  test('a full catalog week produces a positive total', () {
    const all = MealCatalog.all;
    final g = planner.build(all);
    expect(g.lines, isNotEmpty);
    expect(g.total.isPositive, isTrue);
    expect(g.total.currency, 'UAH');
    // Sorted most-expensive first.
    for (var i = 1; i < g.lines.length; i++) {
      expect(g.lines[i - 1].cost.minorUnits,
          greaterThanOrEqualTo(g.lines[i].cost.minorUnits));
    }
  });
}

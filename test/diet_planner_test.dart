import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/food/application/diet_planner.dart';
import 'package:lifeos/features/food/data/meal_catalog.dart';
import 'package:lifeos/features/food/data/ua_store_price_catalog.dart';
import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/domain/seasonal.dart';

void main() {
  group('DietPlanner', () {
    const planner = DietPlanner();

    test('fits the calorie target and covers the main meals', () {
      final plan = planner.plan(targetKcal: 2100, proteinTargetG: 140);

      final slots = plan.meals.map((m) => m.slot).toSet();
      expect(slots, containsAll([MealSlot.breakfast, MealSlot.lunch, MealSlot.dinner]));
      // Within a sane band of the target (catalog is discrete, ±15%).
      expect(plan.total.kcal, inInclusiveRange(2100 * 0.85, 2100 * 1.15));
      expect(plan.total.proteinG, greaterThan(100));
    });

    test('is deterministic for a seed and varies across seeds', () {
      final a1 = planner.plan(targetKcal: 2000, proteinTargetG: 120, seed: 3);
      final a2 = planner.plan(targetKcal: 2000, proteinTargetG: 120, seed: 3);
      expect(a1, equals(a2));

      final ids = <String>{
        for (var s = 0; s < 5; s++)
          planner
              .plan(targetKcal: 2000, proteinTargetG: 120, seed: s)
              .meals
              .map((m) => m.id)
              .join(','),
      };
      expect(ids.length, greaterThan(1)); // menus rotate day to day
    });

    test('low-carb diet biases the week toward fewer carbs on average', () {
      var plainCarbs = 0;
      var lowCarbs = 0;
      for (var s = 0; s < 7; s++) {
        plainCarbs +=
            planner.plan(targetKcal: 2000, proteinTargetG: 120, seed: s).total.carbsG;
        lowCarbs += planner
            .plan(targetKcal: 2000, proteinTargetG: 120, seed: s, dietId: 'lowCarb')
            .total
            .carbsG;
      }
      expect(lowCarbs, lessThan(plainCarbs));
    });

    test('high-protein diet biases the week toward more protein on average', () {
      var plainProtein = 0;
      var highProtein = 0;
      for (var s = 0; s < 7; s++) {
        plainProtein += planner
            .plan(targetKcal: 2000, proteinTargetG: 120, seed: s)
            .total
            .proteinG;
        highProtein += planner
            .plan(
                targetKcal: 2000,
                proteinTargetG: 120,
                seed: s,
                dietId: 'highProtein')
            .total
            .proteinG;
      }
      expect(highProtein, greaterThan(plainProtein));
    });

    test('a summer menu uses more in-season produce than a winter one', () {
      int seasonSum(int planMonth, int evalMonth) {
        var total = 0;
        for (var s = 0; s < 7; s++) {
          final plan = planner.plan(
              targetKcal: 2000,
              proteinTargetG: 120,
              seed: s,
              month: planMonth);
          for (final m in plan.meals) {
            total += seasonalScore(
                m.ingredients.map((i) => i.productId), evalMonth);
          }
        }
        return total;
      }

      // Planned for August vs January, both judged by August seasonality.
      expect(seasonSum(8, 8), greaterThan(seasonSum(1, 8)));
    });
  });

  group('MealCostCalculator (UA stores)', () {
    const cost = MealCostCalculator(UaStorePriceCatalog());

    test('prices every catalog meal in all three stores', () {
      for (final meal in MealCatalog.all) {
        final totals = cost.basketTotals(meal);
        expect(totals.length, 3, reason: meal.id);
        for (final total in totals.values) {
          expect(total.isPositive, isTrue);
          expect(total.currency, 'UAH');
        }
      }
    });

    test('cheapest store is really the cheapest', () {
      final meal = MealCatalog.breakfasts.first; // запіканка
      final totals = cost.basketTotals(meal);
      final (store, price) = cost.cheapest(meal)!;
      for (final entry in totals.entries) {
        expect(price <= entry.value, isTrue);
      }
      expect(store.id, 's1'); // tier 1 is cheapest across the seeded catalog
    });
  });
}

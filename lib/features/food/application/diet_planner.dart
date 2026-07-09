import 'package:equatable/equatable.dart';
import 'package:lifeos/features/food/data/meal_catalog.dart';
import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/domain/repositories/store_price_source.dart';
import 'package:lifeos/shared/models/money.dart';

/// A full day of recommended meals.
class DayPlan extends Equatable {
  final List<MealOption> meals;
  final NutritionFacts total;

  const DayPlan({required this.meals, required this.total});

  @override
  List<Object?> get props => [meals, total];
}

/// The built-in dietitian's planner. Pure and deterministic: given a calorie /
/// protein target (from the FitnessCalculator) and a seed (day of year +
/// shuffle offset), it scores every breakfast × lunch × dinner × snack-subset
/// combination and picks from the best-fitting few — so the menu hits the
/// target, favours enough protein, and still varies day to day.
class DietPlanner {
  const DietPlanner();

  DayPlan plan({
    required int targetKcal,
    required int proteinTargetG,
    int seed = 0,
    Map<MealSlot, int> slotOffsets = const {},
  }) {
    final snackSubsets = _snackSubsets(MealCatalog.snacks);
    final scored = <(double, List<MealOption>)>[];

    for (final b in MealCatalog.breakfasts) {
      for (final l in MealCatalog.lunches) {
        for (final d in MealCatalog.dinners) {
          for (final snacks in snackSubsets) {
            final meals = [b, l, d, ...snacks];
            final total = meals.fold(NutritionFacts.zero, (s, m) => s + m.nutrition);
            final kcalMiss = (total.kcal - targetKcal).abs().toDouble();
            final proteinMiss =
                (proteinTargetG - total.proteinG).clamp(0, 1 << 31).toDouble();
            scored.add((kcalMiss + 2 * proteinMiss, meals));
          }
        }
      }
    }

    scored.sort((a, b) => a.$1.compareTo(b.$1));
    // Rotate among the 5 best fits for day-to-day variety.
    var pick = scored[seed.abs() % 5].$2;

    // Manual per-slot swaps ("другой завтрак"): rotate that slot through the
    // catalog while keeping the rest of the day.
    if (slotOffsets.isNotEmpty) {
      pick = [
        for (final meal in pick) _swapped(meal, slotOffsets[meal.slot] ?? 0),
      ];
    }

    // Portion scaling: nudge serving sizes (±10–15%) so the day lands right on
    // the target instead of the nearest discrete combination.
    final rawKcal =
        pick.fold(NutritionFacts.zero, (s, m) => s + m.nutrition).kcal;
    final factor = rawKcal <= 0
        ? 1.0
        : (targetKcal / rawKcal).clamp(0.85, 1.15).toDouble();
    final meals = [for (final m in pick) m.scaled(factor)];

    return DayPlan(
      meals: meals,
      total: meals.fold(NutritionFacts.zero, (s, m) => s + m.nutrition),
    );
  }

  MealOption _swapped(MealOption meal, int offset) {
    if (offset == 0 || meal.slot == MealSlot.snack) return meal;
    final options = switch (meal.slot) {
      MealSlot.breakfast => MealCatalog.breakfasts,
      MealSlot.lunch => MealCatalog.lunches,
      MealSlot.dinner => MealCatalog.dinners,
      MealSlot.snack => MealCatalog.snacks,
    };
    final index = options.indexWhere((m) => m.id == meal.id);
    if (index == -1) return meal;
    return options[(index + offset) % options.length];
  }

  /// All subsets of the snack list with 0–2 items.
  List<List<MealOption>> _snackSubsets(List<MealOption> snacks) {
    final subsets = <List<MealOption>>[[]];
    for (var i = 0; i < snacks.length; i++) {
      subsets.add([snacks[i]]);
      for (var j = i + 1; j < snacks.length; j++) {
        subsets.add([snacks[i], snacks[j]]);
      }
    }
    return subsets;
  }
}

/// Prices a meal's shopping basket per store (one standard pack per distinct
/// ingredient) and finds the cheapest store.
class MealCostCalculator {
  final StorePriceSource _prices;
  const MealCostCalculator(this._prices);

  /// store → basket total for [meal]. Stores missing a quote for any
  /// ingredient are skipped.
  Map<Store, Money> basketTotals(MealOption meal) {
    final productIds = meal.ingredients.map((i) => i.productId).toSet();
    final totals = <Store, Money>{};
    for (final store in _prices.stores) {
      var total = const Money.zero(currency: 'UAH');
      var complete = true;
      for (final id in productIds) {
        final quote = _quoteFor(id, store);
        if (quote == null) {
          complete = false;
          break;
        }
        total = total + quote.price;
      }
      if (complete) totals[store] = total;
    }
    return totals;
  }

  /// The cheapest (store, total) pair, or null when nothing is priced.
  (Store, Money)? cheapest(MealOption meal) {
    final totals = basketTotals(meal);
    if (totals.isEmpty) return null;
    final entry = totals.entries
        .reduce((a, b) => a.value <= b.value ? a : b);
    return (entry.key, entry.value);
  }

  /// Per-ingredient quotes for [meal] in [store] (for the breakdown UI).
  List<(String, StoreQuote)> breakdown(MealOption meal, Store store) {
    final productIds = meal.ingredients.map((i) => i.productId).toSet();
    return [
      for (final id in productIds)
        if (_quoteFor(id, store) case final q?) (id, q),
    ];
  }

  StoreQuote? _quoteFor(String productId, Store store) {
    for (final q in _prices.quotesFor(productId)) {
      if (q.store == store) return q;
    }
    return null;
  }
}

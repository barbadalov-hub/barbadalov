import 'package:equatable/equatable.dart';
import 'package:lifeos/features/food/data/meal_catalog.dart';
import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/domain/repositories/store_price_source.dart';
import 'package:lifeos/features/food/domain/seasonal.dart';
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

  // Each slot's share of the day's calories (two snacks fill the rest).
  static const _bShare = 0.28;
  static const _lShare = 0.32;
  static const _dShare = 0.28;
  static const _sShare = 0.06; // per snack, ×2

  DayPlan plan({
    required int targetKcal,
    required int proteinTargetG,
    int seed = 0,
    Map<MealSlot, int> slotOffsets = const {},
    String? dietId,
    int? month,
  }) {
    // Pick each slot independently against a per-slot calorie budget — O(n) in
    // the catalog size, so it scales to a large menu (the old full-combination
    // search was O(breakfasts × lunches × dinners × 2^snacks)).
    MealOption bestFor(List<MealOption> options, double budget, int rot) {
      final ranked = [...options]
        ..sort((a, b) => _slotScore(a, budget, dietId, month)
            .compareTo(_slotScore(b, budget, dietId, month)));
      final topN = ranked.length < 5 ? ranked.length : 5;
      return ranked[rot.abs() % topN];
    }

    final b = bestFor(MealCatalog.breakfasts, targetKcal * _bShare, seed);
    final l = bestFor(MealCatalog.lunches, targetKcal * _lShare, seed);
    final d = bestFor(MealCatalog.dinners, targetKcal * _dShare, seed);

    // Two distinct snacks near the snack budget.
    final snacksRanked = [...MealCatalog.snacks]
      ..sort((a, b) => _slotScore(a, targetKcal * _sShare, dietId, month)
          .compareTo(_slotScore(b, targetKcal * _sShare, dietId, month)));
    final snackPicks = <MealOption>[];
    for (var i = 0; snackPicks.length < 2 && i < snacksRanked.length; i++) {
      final s = snacksRanked[(seed.abs() + i) % snacksRanked.length];
      if (!snackPicks.contains(s)) snackPicks.add(s);
    }

    var pick = [b, l, d, ...snackPicks];

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

  /// Fitness of one dish for a slot: nearness to the slot's calorie budget,
  /// a mild protein preference, the chosen-diet bias, and a seasonal nudge
  /// toward dishes using produce that is in season this [month]. Lower is
  /// better.
  ///
  /// Preferences use **density** (grams per kcal), not absolute grams: because
  /// the day is scaled to hit the calorie target, the day's total protein/carbs
  /// end up proportional to the picked dishes' protein/carb *density*.
  double _slotScore(MealOption m, double budget, String? dietId, int? month) =>
      (m.nutrition.kcal - budget).abs() -
      _density(m.nutrition.proteinG, m.nutrition.kcal) * 300 +
      _dietTerm(dietId, m.nutrition) -
      (month == null
          ? 0.0
          : seasonalScore(m.ingredients.map((i) => i.productId), month) * 25.0);

  double _density(int grams, int kcal) => kcal <= 0 ? 0.0 : grams / kcal;

  /// A soft bias toward dishes that suit the chosen diet. Positive numbers are
  /// penalties (worse fit). Timing-only diets (fasting) and generally balanced
  /// ones don't change dish selection.
  double _dietTerm(String? dietId, NutritionFacts t) => switch (dietId) {
        'lowCarb' => _density(t.carbsG, t.kcal) * 600, // penalize carb density
        'highProtein' =>
          -_density(t.proteinG, t.kcal) * 600, // reward protein density
        _ => 0.0,
      };

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

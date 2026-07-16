import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/food/application/diet_planner.dart';
import 'package:lifeos/features/food/data/meal_catalog.dart';
import 'package:lifeos/features/food/data/ua_store_price_catalog.dart';
import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/domain/events/food_events.dart';
import 'package:lifeos/features/food/domain/repositories/store_price_source.dart';
import 'package:lifeos/features/food/domain/weekly_groceries.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Grocery prices come from a curated, fully offline catalog of brand-free
/// approximate prices. (There is no live scraping of any retailer.)
final storePriceSourceProvider =
    Provider<StorePriceSource>((ref) => const UaStorePriceCatalog());

final mealCostCalculatorProvider = Provider<MealCostCalculator>(
    (ref) => MealCostCalculator(ref.watch(storePriceSourceProvider)));

final dietPlannerProvider = Provider<DietPlanner>((ref) => const DietPlanner());

final weeklyGroceryPlannerProvider = Provider<WeeklyGroceryPlanner>(
    (ref) => WeeklyGroceryPlanner(ref.watch(storePriceSourceProvider)));

/// The user's **weekly** food budget for the meal planner (minor units, UAH),
/// persisted. Separate from MoneyOS's monthly food-category budget.
class WeeklyFoodBudgetController extends Notifier<int> {
  static const _key = 'diet.foodBudgetWeekly';
  static const _default = 150000; // 1500 UAH / week

  @override
  int build() {
    final v = ref.watch(keyValueStoreProvider).getString(_key);
    return v == null ? _default : (int.tryParse(v) ?? _default);
  }

  void set(int minorUnits) {
    final v = minorUnits.clamp(0, 1 << 30);
    ref.read(keyValueStoreProvider).setString(_key, '$v');
    state = v;
  }
}

final weeklyFoodBudgetProvider =
    NotifierProvider<WeeklyFoodBudgetController, int>(
        WeeklyFoodBudgetController.new);

/// A consolidated shopping list + cost for the currently selected menu week.
final weeklyGroceriesProvider = Provider<WeeklyGroceries?>((ref) {
  final week = ref.watch(weekPlanProvider);
  if (week == null || week.isEmpty) return null;
  final meals = [for (final day in week) ...day.meals];
  return ref.watch(weeklyGroceryPlannerProvider).build(meals);
});

/// Actual money spent on food (the Food expense category) over the last 7 days.
final weeklyFoodSpendProvider = Provider<Money>((ref) {
  final now = ref.watch(clockProvider).now();
  final since = now.subtract(const Duration(days: 7));
  final txs = ref.watch(transactionsProvider).valueOrNull ?? const [];
  var minor = 0;
  for (final t in txs) {
    if (t.isExpense &&
        t.categoryId == DefaultCategories.food.id &&
        t.date.isAfter(since)) {
      minor += t.amount.minorUnits;
    }
  }
  return Money(minor, currency: 'UAH');
});

/// Bump to get a different (still target-fitting) menu for today.
final dietShuffleProvider = StateProvider<int>((ref) => 0);

/// Per-slot manual swaps: "another breakfast" without touching the rest.
final slotSwapProvider =
    StateProvider<Map<MealSlot, int>>((ref) => const {});

/// Today's recommended menu, or null until the profile is filled in.
final dayPlanProvider = Provider<DayPlan?>((ref) {
  final assessment = ref.watch(assessmentProvider);
  if (assessment == null) return null;
  final now = ref.watch(clockProvider).now();
  final dayOfYear = now.difference(DateTime(now.year)).inDays;
  final shuffle = ref.watch(dietShuffleProvider);
  return ref.watch(dietPlannerProvider).plan(
        targetKcal: assessment.targetKcal,
        proteinTargetG: assessment.proteinG,
        seed: dayOfYear + shuffle,
        slotOffsets: ref.watch(slotSwapProvider),
        dietId: ref.watch(selectedDietProvider),
        month: now.month,
      );
});

/// Which day of the selected week the diet menu is showing (0 … 6).
final selectedDietDayProvider = StateProvider<int>((ref) => 0);

/// Which upcoming week the menu is showing (0 = this week … 3).
final selectedMenuWeekProvider = StateProvider<int>((ref) => 0);

/// The diet the user picked from the catalog (id, e.g. 'lowCarb'), persisted.
/// Empty string means "none / balanced". Biases the planner's dish choice.
class SelectedDietController extends Notifier<String?> {
  static const _key = 'diet.selected';

  @override
  String? build() {
    final v = ref.watch(keyValueStoreProvider).getString(_key);
    return (v == null || v.isEmpty) ? null : v;
  }

  void select(String? id) {
    ref.read(keyValueStoreProvider).setString(_key, id ?? '');
    state = (id == null || id.isEmpty) ? null : id;
  }
}

final selectedDietProvider =
    NotifierProvider<SelectedDietController, String?>(SelectedDietController.new);

/// A 7-day menu for the selected week. Each day is a target-fitting plan with
/// its own seed (and biased by the chosen diet), so the week varies day to day.
/// Null until the profile is filled in.
final weekPlanProvider = Provider<List<DayPlan>?>((ref) {
  final assessment = ref.watch(assessmentProvider);
  if (assessment == null) return null;
  final now = ref.watch(clockProvider).now();
  final dayOfYear = now.difference(DateTime(now.year)).inDays;
  final shuffle = ref.watch(dietShuffleProvider);
  final week = ref.watch(selectedMenuWeekProvider);
  final dietId = ref.watch(selectedDietProvider);
  final planner = ref.watch(dietPlannerProvider);
  final base = dayOfYear + shuffle + week * 7;
  return [
    for (var i = 0; i < 7; i++)
      (week == 0 && i == 0)
          // Today mirrors the live plan (respects per-slot swaps).
          ? planner.plan(
              targetKcal: assessment.targetKcal,
              proteinTargetG: assessment.proteinG,
              seed: dayOfYear + shuffle,
              slotOffsets: ref.watch(slotSwapProvider),
              dietId: dietId,
              month: now.month,
            )
          : planner.plan(
              targetKcal: assessment.targetKcal,
              proteinTargetG: assessment.proteinG,
              seed: base + i,
              dietId: dietId,
              month: now.add(Duration(days: week * 7 + i)).month,
            ),
  ];
});

/// Meal ids the user has marked as eaten **today**. Persisted with the date so
/// the checklist resets on a new day; toggling publishes a `meal_eaten` event.
class EatenMealsController extends Notifier<Set<String>> {
  static const _key = 'diet.eaten';

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  Set<String> build() {
    final store = ref.watch(jsonStoreProvider);
    final today = _dayKey(ref.read(clockProvider).now());
    final raw = store.loadObject<Map<String, dynamic>>(
      _key,
      (j) => j,
      fallback: const {},
    );
    if (raw['date'] != today) return {};
    return ((raw['ids'] as List<dynamic>?) ?? const [])
        .cast<String>()
        .toSet();
  }

  void toggle(String mealId) {
    final now = ref.read(clockProvider).now();
    final next = Set<String>.from(state);
    final eaten = !next.contains(mealId);
    if (eaten) {
      next.add(mealId);
    } else {
      next.remove(mealId);
    }
    ref.read(jsonStoreProvider).saveObject<Map<String, dynamic>>(
      _key,
      {'date': _dayKey(now), 'ids': next.toList()},
      (m) => m,
    );
    state = next;

    final meal = MealCatalog.all.where((m) => m.id == mealId).firstOrNull;
    ref.read(eventBusProvider).publish(MealEatenEvent(
          id: ref.read(idServiceProvider).newId(),
          userId: 'local',
          occurredAt: now,
          mealId: mealId,
          eaten: eaten,
          kcal: meal?.nutrition.kcal ?? 0,
        ));
  }
}

final eatenMealsProvider =
    NotifierProvider<EatenMealsController, Set<String>>(
        EatenMealsController.new);

/// A food the user logged manually (beyond the planned menu).
class ManualFoodEntry {
  final String id;
  final String name;
  final NutritionFacts nutrition;
  const ManualFoodEntry(
      {required this.id, required this.name, required this.nutrition});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kcal': nutrition.kcal,
        'p': nutrition.proteinG,
        'f': nutrition.fatG,
        'c': nutrition.carbsG,
      };

  factory ManualFoodEntry.fromJson(Map<String, dynamic> j) => ManualFoodEntry(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        nutrition: NutritionFacts(
          kcal: (j['kcal'] as num?)?.toInt() ?? 0,
          proteinG: (j['p'] as num?)?.toInt() ?? 0,
          fatG: (j['f'] as num?)?.toInt() ?? 0,
          carbsG: (j['c'] as num?)?.toInt() ?? 0,
        ),
      );
}

/// Today's manually-logged foods (resets on a new day).
class ManualFoodController extends Notifier<List<ManualFoodEntry>> {
  static const _key = 'diet.manualFood';
  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  List<ManualFoodEntry> build() {
    final today = _dayKey(ref.read(clockProvider).now());
    final raw = ref.watch(jsonStoreProvider).loadObject<Map<String, dynamic>>(
          _key,
          (j) => j,
          fallback: const {},
        );
    if (raw['date'] != today) return [];
    return [
      for (final e in (raw['items'] as List<dynamic>? ?? const []))
        ManualFoodEntry.fromJson(e as Map<String, dynamic>),
    ];
  }

  void add(String name, NutritionFacts nutrition) {
    if (name.trim().isEmpty || nutrition.kcal <= 0) return;
    final entry = ManualFoodEntry(
        id: ref.read(idServiceProvider).newId(),
        name: name.trim(),
        nutrition: nutrition);
    _persist([...state, entry]);
  }

  void remove(String id) => _persist([for (final e in state) if (e.id != id) e]);

  void _persist(List<ManualFoodEntry> next) {
    ref.read(jsonStoreProvider).saveObject<Map<String, dynamic>>(
      _key,
      {
        'date': _dayKey(ref.read(clockProvider).now()),
        'items': [for (final e in next) e.toJson()],
      },
      (m) => m,
    );
    state = next;
  }
}

final manualFoodProvider =
    NotifierProvider<ManualFoodController, List<ManualFoodEntry>>(
        ManualFoodController.new);

/// Calories + macros consumed today (checked-off meals + manual foods). Meals
/// are looked up in the full catalog so a reshuffled plan never loses them.
final consumedNutritionProvider = Provider<NutritionFacts>((ref) {
  final eaten = ref.watch(eatenMealsProvider);
  final fromMeals = MealCatalog.all
      .where((m) => eaten.contains(m.id))
      .fold(NutritionFacts.zero, (sum, m) => sum + m.nutrition);
  final fromManual = ref
      .watch(manualFoodProvider)
      .fold(NutritionFacts.zero, (sum, e) => sum + e.nutrition);
  return fromMeals + fromManual;
});

/// The next not-yet-eaten meal from today's plan (for the Today screen).
final nextMealProvider = Provider<MealOption?>((ref) {
  final plan = ref.watch(dayPlanProvider);
  if (plan == null) return null;
  final eaten = ref.watch(eatenMealsProvider);
  for (final meal in plan.meals) {
    if (!eaten.contains(meal.id)) return meal;
  }
  return null;
});

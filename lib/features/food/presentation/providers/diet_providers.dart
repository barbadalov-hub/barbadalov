import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/food/application/diet_planner.dart';
import 'package:lifeos/features/food/data/backend_price_source.dart';
import 'package:lifeos/features/food/data/meal_catalog.dart';
import 'package:lifeos/features/food/data/ua_store_price_catalog.dart';
import 'package:lifeos/features/food/data/zakaz_price_source.dart';
import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/domain/events/food_events.dart';
import 'package:lifeos/features/food/domain/repositories/store_price_source.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Live price cache: productId → chainId → kopecks, fetched from the public
/// zakaz.ua API (Novus/METRO/Auchan, no account needed) and persisted.
class LivePricesController extends Notifier<Map<String, Map<String, int>>> {
  static const _key = 'prices.live';

  @override
  Map<String, Map<String, int>> build() {
    final raw = ref.watch(jsonStoreProvider).loadObject<Map<String, dynamic>>(
          _key,
          (j) => j,
          fallback: const {},
        );
    final prices = raw['prices'];
    if (prices is! Map<String, dynamic>) return {};
    return {
      for (final e in prices.entries)
        e.key: {
          for (final c in (e.value as Map<String, dynamic>).entries)
            c.key: c.value as int,
        },
    };
  }

  /// Fetch fresh prices for [productIds]. Returns how many quotes landed
  /// (0 usually means offline / web-CORS — offline catalog stays in charge).
  /// Pulls Novus/METRO/Auchan from the public zakaz.ua API and, when a price
  /// scraper backend is configured, АТБ/Сільпо from it too — in parallel.
  Future<int> refresh(Set<String> productIds) async {
    final results = await Future.wait([
      ZakazUaClient().fetchAll(productIds),
      BackendPriceClient().fetchAll(productIds),
    ]);
    // Merge both sources per product (chain maps don't overlap).
    final fetched = <String, Map<String, int>>{};
    for (final source in results) {
      for (final e in source.entries) {
        (fetched[e.key] ??= {}).addAll(e.value);
      }
    }
    if (fetched.isEmpty) return 0;
    final merged = {
      for (final e in {...state, ...fetched}.keys)
        e: {...?state[e], ...?fetched[e]},
    };
    ref.read(jsonStoreProvider).saveObject<Map<String, dynamic>>(
      _key,
      {
        'ts': ref.read(clockProvider).now().toIso8601String(),
        'prices': merged,
      },
      (m) => m,
    );
    state = merged;
    return fetched.values.fold<int>(0, (n, m) => n + m.length);
  }
}

final livePricesProvider =
    NotifierProvider<LivePricesController, Map<String, Map<String, int>>>(
        LivePricesController.new);

/// Ukrainian stores: curated АТБ/Сільпо catalog + live Novus/METRO/Auchan
/// overlay when the internet has been reached at least once.
final storePriceSourceProvider = Provider<StorePriceSource>((ref) {
  return CompositePriceSource(
    const UaStorePriceCatalog(),
    ref.watch(livePricesProvider),
  );
});

final mealCostCalculatorProvider = Provider<MealCostCalculator>(
    (ref) => MealCostCalculator(ref.watch(storePriceSourceProvider)));

final dietPlannerProvider = Provider<DietPlanner>((ref) => const DietPlanner());

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
      );
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

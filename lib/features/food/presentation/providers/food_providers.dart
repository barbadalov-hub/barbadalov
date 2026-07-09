import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/food/application/food_use_cases.dart';
import 'package:lifeos/features/food/data/food_repository_impl.dart';
import 'package:lifeos/features/food/domain/entities/food_item.dart';
import 'package:lifeos/features/food/domain/entities/meal_plan.dart';
import 'package:lifeos/features/food/domain/entities/recipe.dart';
import 'package:lifeos/features/food/domain/entities/shopping_item.dart';
import 'package:lifeos/features/food/domain/repositories/food_repository.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  final now = ref.watch(clockProvider).now();
  final store = ref.watch(jsonStoreProvider);
  const pantryKey = 'food.pantry';
  const shoppingKey = 'food.shopping';
  const recipesKey = 'food.recipes';
  const mealPlanKey = 'food.mealPlan';
  final impl = FoodRepositoryImpl(
    seedPantry: store.loadList(
      pantryKey,
      FoodItem.fromJson,
      fallback: _defaultPantry(now),
    ),
    seedShopping: store.loadList(
      shoppingKey,
      ShoppingItem.fromJson,
      fallback: _defaultShopping,
    ),
    seedRecipes: store.loadList(
      recipesKey,
      Recipe.fromJson,
      fallback: _defaultRecipes,
    ),
    seedMealPlan: store.loadObject(
      mealPlanKey,
      MealPlan.fromJson,
      fallback: const MealPlan(),
    ),
    onPantryChanged: (items) =>
        store.saveList(pantryKey, items, (i) => i.toJson()),
    onShoppingChanged: (items) =>
        store.saveList(shoppingKey, items, (i) => i.toJson()),
    onRecipesChanged: (items) =>
        store.saveList(recipesKey, items, (i) => i.toJson()),
    onMealPlanChanged: (plan) =>
        store.saveObject(mealPlanKey, plan, (p) => p.toJson()),
  );
  ref.onDispose(impl.dispose);
  return impl;
});

const _defaultRecipes = <Recipe>[
  Recipe(
    id: 'seed_r_omelette',
    name: 'Veggie omelette',
    emoji: '🍳',
    ingredients: ['Eggs', 'Tomatoes', 'Cheese', 'Spinach'],
  ),
  Recipe(
    id: 'seed_r_pasta',
    name: 'Tomato pasta',
    emoji: '🍝',
    ingredients: ['Pasta', 'Tomatoes', 'Garlic', 'Basil'],
  ),
];

List<FoodItem> _defaultPantry(DateTime now) => [
      FoodItem(
        id: 'seed_milk',
        name: 'Milk',
        emoji: '🥛',
        addedAt: now,
        expiry: now.add(const Duration(days: 2)),
      ),
      FoodItem(
        id: 'seed_eggs',
        name: 'Eggs',
        emoji: '🥚',
        quantity: 10,
        addedAt: now,
        expiry: now.add(const Duration(days: 9)),
      ),
      FoodItem(
        id: 'seed_bread',
        name: 'Bread',
        emoji: '🍞',
        addedAt: now,
        expiry: now.add(const Duration(days: 1)),
      ),
    ];

const _defaultShopping = <ShoppingItem>[
  ShoppingItem(id: 'seed_s1', name: 'Tomatoes'),
  ShoppingItem(id: 'seed_s2', name: 'Chicken'),
];

final pantryProvider = StreamProvider<List<FoodItem>>((ref) {
  ref.watch(coreEngineProvider);
  return ref.watch(foodRepositoryProvider).watchPantry();
});

final shoppingProvider = StreamProvider<List<ShoppingItem>>((ref) {
  return ref.watch(foodRepositoryProvider).watchShopping();
});

/// Pantry items expiring within 3 days — surfaced on Today and used by AI.
final expiringSoonProvider = Provider<List<FoodItem>>((ref) {
  final now = ref.watch(clockProvider).now();
  final items = ref.watch(pantryProvider).valueOrNull ?? const [];
  return items.where((i) => i.isExpiringSoon(now) || i.isExpired(now)).toList();
});

final addFoodItemProvider = Provider<AddFoodItem>((ref) => AddFoodItem(
      ref.watch(foodRepositoryProvider),
      ref.watch(eventBusProvider),
      ref.watch(idServiceProvider),
      ref.watch(clockProvider),
    ));

final addShoppingItemProvider = Provider<AddShoppingItem>((ref) =>
    AddShoppingItem(
        ref.watch(foodRepositoryProvider), ref.watch(idServiceProvider)));

final toggleShoppingItemProvider =
    Provider<ToggleShoppingItem>((ref) => ToggleShoppingItem(
          ref.watch(foodRepositoryProvider),
          ref.watch(eventBusProvider),
          ref.watch(idServiceProvider),
          ref.watch(clockProvider),
        ));

// --- Recipes & meal plan ---------------------------------------------------
final recipesProvider = StreamProvider<List<Recipe>>((ref) {
  ref.watch(coreEngineProvider);
  return ref.watch(foodRepositoryProvider).watchRecipes();
});

final mealPlanProvider = StreamProvider<MealPlan>((ref) {
  return ref.watch(foodRepositoryProvider).watchMealPlan();
});

final addRecipeProvider = Provider<AddRecipe>((ref) =>
    AddRecipe(ref.watch(foodRepositoryProvider), ref.watch(idServiceProvider)));

final addRecipeToShoppingProvider = Provider<AddRecipeToShopping>((ref) =>
    AddRecipeToShopping(
        ref.watch(foodRepositoryProvider), ref.watch(idServiceProvider)));

final setMealProvider =
    Provider<SetMeal>((ref) => SetMeal(ref.watch(foodRepositoryProvider)));

// --- Food budget -----------------------------------------------------------
/// The monthly food-spending target. Persisted; default $600.
class FoodBudgetController extends Notifier<Money> {
  static const _key = 'food.budgetMinor';
  static const _defaultMinor = 60000;

  @override
  Money build() {
    final raw = ref.watch(keyValueStoreProvider).getString(_key);
    return Money(int.tryParse(raw ?? '') ?? _defaultMinor);
  }

  void setTarget(Money target) {
    ref.read(keyValueStoreProvider).setString(_key, '${target.minorUnits}');
    state = target;
  }
}

final foodBudgetProvider =
    NotifierProvider<FoodBudgetController, Money>(FoodBudgetController.new);

/// This month's spending in the Food category, derived live from MoneyOS.
final foodSpentThisMonthProvider = Provider<Money>((ref) {
  final now = ref.watch(clockProvider).now();
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? const [];
  var minor = 0;
  for (final t in transactions) {
    if (t.isExpense &&
        t.categoryId == DefaultCategories.food.id &&
        t.date.year == now.year &&
        t.date.month == now.month) {
      minor += t.amount.minorUnits;
    }
  }
  return Money(minor);
});

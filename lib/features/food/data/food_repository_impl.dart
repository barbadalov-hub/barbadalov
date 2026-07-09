import 'dart:async';

import 'package:lifeos/features/food/domain/entities/food_item.dart';
import 'package:lifeos/features/food/domain/entities/meal_plan.dart';
import 'package:lifeos/features/food/domain/entities/recipe.dart';
import 'package:lifeos/features/food/domain/entities/shopping_item.dart';
import 'package:lifeos/features/food/domain/repositories/food_repository.dart';

/// In-memory FoodOS store with reactive pantry / shopping / recipes / meal-plan
/// streams. Each mutation calls the matching `onChanged` so a provider persists.
class FoodRepositoryImpl implements FoodRepository {
  FoodRepositoryImpl({
    List<FoodItem> seedPantry = const [],
    List<ShoppingItem> seedShopping = const [],
    List<Recipe> seedRecipes = const [],
    MealPlan seedMealPlan = const MealPlan(),
    this.onPantryChanged,
    this.onShoppingChanged,
    this.onRecipesChanged,
    this.onMealPlanChanged,
  })  : _pantry = List.of(seedPantry),
        _shopping = List.of(seedShopping),
        _recipes = List.of(seedRecipes),
        _mealPlan = seedMealPlan;

  final List<FoodItem> _pantry;
  final List<ShoppingItem> _shopping;
  final List<Recipe> _recipes;
  MealPlan _mealPlan;

  final void Function(List<FoodItem> items)? onPantryChanged;
  final void Function(List<ShoppingItem> items)? onShoppingChanged;
  final void Function(List<Recipe> items)? onRecipesChanged;
  final void Function(MealPlan plan)? onMealPlanChanged;

  final StreamController<List<FoodItem>> _pantryController =
      StreamController<List<FoodItem>>.broadcast();
  final StreamController<List<ShoppingItem>> _shoppingController =
      StreamController<List<ShoppingItem>>.broadcast();
  final StreamController<List<Recipe>> _recipesController =
      StreamController<List<Recipe>>.broadcast();
  final StreamController<MealPlan> _mealPlanController =
      StreamController<MealPlan>.broadcast();

  // --- Pantry --------------------------------------------------------------
  @override
  void addFoodItem(FoodItem item) {
    _pantry.add(item);
    _emit(_pantryController, pantry());
    onPantryChanged?.call(pantry());
  }

  @override
  List<FoodItem> pantry() => List.unmodifiable(_pantry);

  @override
  Stream<List<FoodItem>> watchPantry() async* {
    yield pantry();
    yield* _pantryController.stream;
  }

  // --- Shopping ------------------------------------------------------------
  @override
  void addShoppingItem(ShoppingItem item) {
    _shopping.add(item);
    _emit(_shoppingController, shopping());
    onShoppingChanged?.call(shopping());
  }

  @override
  void toggleShoppingItem(String id) {
    final i = _shopping.indexWhere((s) => s.id == id);
    if (i == -1) return;
    _shopping[i] = _shopping[i].toggle();
    _emit(_shoppingController, shopping());
    onShoppingChanged?.call(shopping());
  }

  @override
  void clearCheckedShopping() {
    _shopping.removeWhere((s) => s.checked);
    _emit(_shoppingController, shopping());
    onShoppingChanged?.call(shopping());
  }

  @override
  List<ShoppingItem> shopping() => List.unmodifiable(_shopping);

  @override
  Stream<List<ShoppingItem>> watchShopping() async* {
    yield shopping();
    yield* _shoppingController.stream;
  }

  // --- Recipes -------------------------------------------------------------
  @override
  void addRecipe(Recipe recipe) {
    _recipes.add(recipe);
    _emit(_recipesController, recipes());
    onRecipesChanged?.call(recipes());
  }

  @override
  List<Recipe> recipes() => List.unmodifiable(_recipes);

  @override
  Stream<List<Recipe>> watchRecipes() async* {
    yield recipes();
    yield* _recipesController.stream;
  }

  // --- Meal plan -----------------------------------------------------------
  @override
  MealPlan mealPlan() => _mealPlan;

  @override
  void setMeal(int weekday, String meal) {
    _mealPlan = _mealPlan.withMeal(weekday, meal);
    _emit(_mealPlanController, _mealPlan);
    onMealPlanChanged?.call(_mealPlan);
  }

  @override
  Stream<MealPlan> watchMealPlan() async* {
    yield _mealPlan;
    yield* _mealPlanController.stream;
  }

  void _emit<T>(StreamController<T> controller, T value) {
    if (!controller.isClosed) controller.add(value);
  }

  Future<void> dispose() async {
    await _pantryController.close();
    await _shoppingController.close();
    await _recipesController.close();
    await _mealPlanController.close();
  }
}

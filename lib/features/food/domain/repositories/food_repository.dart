import 'package:lifeos/features/food/domain/entities/food_item.dart';
import 'package:lifeos/features/food/domain/entities/meal_plan.dart';
import 'package:lifeos/features/food/domain/entities/recipe.dart';
import 'package:lifeos/features/food/domain/entities/shopping_item.dart';

abstract class FoodRepository {
  // Pantry
  void addFoodItem(FoodItem item);
  List<FoodItem> pantry();
  Stream<List<FoodItem>> watchPantry();

  // Shopping list
  void addShoppingItem(ShoppingItem item);
  void toggleShoppingItem(String id);
  void clearCheckedShopping();
  List<ShoppingItem> shopping();
  Stream<List<ShoppingItem>> watchShopping();

  // Recipes
  void addRecipe(Recipe recipe);
  List<Recipe> recipes();
  Stream<List<Recipe>> watchRecipes();

  // Meal plan
  MealPlan mealPlan();
  void setMeal(int weekday, String meal);
  Stream<MealPlan> watchMealPlan();
}

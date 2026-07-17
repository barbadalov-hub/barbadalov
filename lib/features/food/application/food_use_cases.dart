import 'package:lifeos/core/errors/failures.dart';
import 'package:lifeos/core/events/event_bus.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/id_service.dart';
import 'package:lifeos/core/utils/result.dart';
import 'package:lifeos/features/food/domain/entities/food_item.dart';
import 'package:lifeos/features/food/domain/entities/recipe.dart';
import 'package:lifeos/features/food/domain/entities/shopping_item.dart';
import 'package:lifeos/features/food/domain/events/food_events.dart';
import 'package:lifeos/features/food/domain/repositories/food_repository.dart';

/// FoodOS write use cases. Each mutation persists then publishes a [LifeEvent].
class AddFoodItem {
  final FoodRepository _repository;
  final EventBus _eventBus;
  final IdService _idService;
  final Clock _clock;

  const AddFoodItem(
    this._repository,
    this._eventBus,
    this._idService,
    this._clock,
  );

  Result<FoodItem> call({
    required String name,
    String emoji = '🍎',
    int quantity = 1,
    DateTime? expiry,
    String? productId,
    String userId = 'local',
  }) {
    if (name.trim().isEmpty) {
      return const Err(ValidationFailure('Name cannot be empty.'));
    }
    final item = FoodItem(
      id: _idService.newId(),
      name: name.trim(),
      emoji: emoji,
      quantity: quantity,
      expiry: expiry,
      productId: productId,
      addedAt: _clock.now(),
    );
    _repository.addFoodItem(item);
    _eventBus.publish(FoodAddedEvent(
      id: _idService.newId(),
      userId: userId,
      occurredAt: _clock.now(),
      foodItemId: item.id,
      name: item.name,
      expiry: item.expiry,
    ));
    return Ok(item);
  }
}

class AddShoppingItem {
  final FoodRepository _repository;
  final IdService _idService;

  const AddShoppingItem(this._repository, this._idService);

  Result<ShoppingItem> call(String name) {
    if (name.trim().isEmpty) {
      return const Err(ValidationFailure('Name cannot be empty.'));
    }
    final item = ShoppingItem(id: _idService.newId(), name: name.trim());
    _repository.addShoppingItem(item);
    return Ok(item);
  }
}

class AddRecipe {
  final FoodRepository _repository;
  final IdService _idService;

  const AddRecipe(this._repository, this._idService);

  Result<Recipe> call({
    required String name,
    String emoji = '🍽️',
    List<String> ingredients = const [],
  }) {
    if (name.trim().isEmpty) {
      return const Err(ValidationFailure('Name cannot be empty.'));
    }
    final recipe = Recipe(
      id: _idService.newId(),
      name: name.trim(),
      emoji: emoji,
      ingredients: ingredients
          .map((i) => i.trim())
          .where((i) => i.isNotEmpty)
          .toList(),
    );
    _repository.addRecipe(recipe);
    return Ok(recipe);
  }
}

/// Pushes a recipe's ingredients onto the shopping list.
class AddRecipeToShopping {
  final FoodRepository _repository;
  final IdService _idService;

  const AddRecipeToShopping(this._repository, this._idService);

  void call(Recipe recipe) {
    for (final ingredient in recipe.ingredients) {
      _repository.addShoppingItem(
        ShoppingItem(id: _idService.newId(), name: ingredient),
      );
    }
  }
}

class SetMeal {
  final FoodRepository _repository;
  const SetMeal(this._repository);

  void call(int weekday, String meal) => _repository.setMeal(weekday, meal);
}

class ToggleShoppingItem {
  final FoodRepository _repository;
  final EventBus _eventBus;
  final IdService _idService;
  final Clock _clock;

  const ToggleShoppingItem(
    this._repository,
    this._eventBus,
    this._idService,
    this._clock,
  );

  void call(ShoppingItem item, {String userId = 'local'}) {
    _repository.toggleShoppingItem(item.id);
    _eventBus.publish(GroceryCheckedEvent(
      id: _idService.newId(),
      userId: userId,
      occurredAt: _clock.now(),
      shoppingItemId: item.id,
      checked: !item.checked,
    ));
  }
}

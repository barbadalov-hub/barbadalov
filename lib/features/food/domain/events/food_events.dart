import 'package:lifeos/core/events/life_event.dart';

class FoodAddedEvent extends LifeEvent {
  final String foodItemId;
  final String name;
  final DateTime? expiry;

  const FoodAddedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required this.foodItemId,
    required this.name,
    this.expiry,
  });

  @override
  String get type => 'food_added';

  @override
  Map<String, dynamic> toPayload() => {
        'foodItemId': foodItemId,
        'name': name,
        'expiry': expiry?.toIso8601String(),
      };
}

/// Emitted when the user marks a dietitian meal as eaten (or un-eaten).
class MealEatenEvent extends LifeEvent {
  final String mealId;
  final bool eaten;
  final int kcal;

  const MealEatenEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required this.mealId,
    required this.eaten,
    required this.kcal,
  });

  @override
  String get type => 'meal_eaten';

  @override
  Map<String, dynamic> toPayload() =>
      {'mealId': mealId, 'eaten': eaten, 'kcal': kcal};
}

class GroceryCheckedEvent extends LifeEvent {
  final String shoppingItemId;
  final bool checked;

  const GroceryCheckedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required this.shoppingItemId,
    required this.checked,
  });

  @override
  String get type => 'grocery_checked';

  @override
  Map<String, dynamic> toPayload() => {
        'shoppingItemId': shoppingItemId,
        'checked': checked,
      };
}

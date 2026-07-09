import 'package:equatable/equatable.dart';

/// A weekly meal plan: a meal (free text or recipe name) per weekday.
/// Keys are `DateTime.weekday` values (1 = Monday … 7 = Sunday).
class MealPlan extends Equatable {
  final Map<int, String> meals;

  const MealPlan({this.meals = const {}});

  String mealFor(int weekday) => meals[weekday] ?? '';

  MealPlan withMeal(int weekday, String meal) {
    final next = Map<int, String>.from(meals);
    if (meal.trim().isEmpty) {
      next.remove(weekday);
    } else {
      next[weekday] = meal.trim();
    }
    return MealPlan(meals: next);
  }

  Map<String, dynamic> toJson() =>
      meals.map((k, v) => MapEntry('$k', v));

  factory MealPlan.fromJson(Map<String, dynamic> json) => MealPlan(
        meals: json.map((k, v) => MapEntry(int.parse(k), v as String)),
      );

  @override
  List<Object?> get props => [meals];
}

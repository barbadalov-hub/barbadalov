import 'package:lifeos/features/food/domain/cook_from_pantry.dart';
import 'package:lifeos/features/food/domain/entities/nutrition.dart';

/// One day of a pantry-based menu: a dish per main slot, each annotated with
/// how well the pantry covers it.
class PantryDayPlan {
  final PantryMeal? breakfast;
  final PantryMeal? lunch;
  final PantryMeal? dinner;

  const PantryDayPlan({this.breakfast, this.lunch, this.dinner});

  Iterable<PantryMeal> get meals =>
      [breakfast, lunch, dinner].whereType<PantryMeal>();

  /// Total calories of the planned dishes (0 when a slot is empty).
  int get kcal => meals.fold(0, (s, m) => s + m.meal.nutrition.kcal);
}

/// Builds a balanced weekly menu **from what's in the pantry** — no diet, just
/// eat what you bought. Each slot's dishes are ranked by pantry coverage (with
/// soon-to-expire items first), then spread across the week so early days use
/// up perishables and the same dish doesn't repeat back-to-back. Pure —
/// unit-tested.
class PantryWeekPlanner {
  const PantryWeekPlanner();

  List<PantryDayPlan> plan({
    required Set<String> available,
    required List<MealOption> meals,
    Set<String> expiring = const {},
    int days = 7,
  }) {
    const cook = CookFromPantry();

    List<PantryMeal> ranked(MealSlot slot) {
      final list = meals
          .where((m) => m.slot == slot && m.ingredients.isNotEmpty)
          .map((m) => cook.describe(m, available, expiring))
          .toList()
        ..sort(CookFromPantry.byPreference);
      return list;
    }

    final breakfasts = ranked(MealSlot.breakfast);
    final lunches = ranked(MealSlot.lunch);
    final dinners = ranked(MealSlot.dinner);

    PantryMeal? pick(List<PantryMeal> list, int day) =>
        list.isEmpty ? null : list[day % list.length];

    return [
      for (var i = 0; i < days; i++)
        PantryDayPlan(
          breakfast: pick(breakfasts, i),
          lunch: pick(lunches, i),
          dinner: pick(dinners, i),
        ),
    ];
  }
}

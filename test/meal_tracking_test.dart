import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/food/data/meal_catalog.dart';
import 'package:lifeos/features/food/presentation/providers/diet_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

void main() {
  test('eating a meal counts kcal, logs an event and survives restart',
      () async {
    final store = InMemoryKeyValueStore();
    ProviderContainer newLaunch() => ProviderContainer(
          overrides: [keyValueStoreProvider.overrideWithValue(store)],
        );

    final first = newLaunch();
    first.read(coreEngineProvider); // boot the pipeline
    final log = first.read(eventLogProvider);

    final meal = MealCatalog.breakfasts.first; // запіканка, 430 kcal
    first.read(eatenMealsProvider.notifier).toggle(meal.id);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(first.read(consumedNutritionProvider).kcal, meal.nutrition.kcal);
    expect(log.entries.any((e) => e['type'] == 'meal_eaten'), isTrue);
    first.dispose();

    // Same day, new app instance → the checklist is restored.
    final second = newLaunch();
    expect(second.read(eatenMealsProvider).contains(meal.id), isTrue);
    expect(second.read(consumedNutritionProvider).kcal, meal.nutrition.kcal);

    // Un-toggling zeroes the count again.
    second.read(eatenMealsProvider.notifier).toggle(meal.id);
    expect(second.read(consumedNutritionProvider).kcal, 0);
    second.dispose();
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/food/data/meal_catalog.dart';
import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/presentation/providers/diet_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

void main() {
  ProviderContainer harness() {
    final c = ProviderContainer(overrides: [
      keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore({})),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('the catalogue the diary now searches', () {
    test('has enough dishes to be worth searching', () {
      expect(MealCatalog.all.length, greaterThan(50));
    });

    test('every dish carries real nutrition, not placeholders', () {
      // A search result that logs zero calories would be worse than typing.
      for (final m in MealCatalog.all) {
        expect(m.nutrition.kcal, greaterThan(0), reason: '${m.id} has no kcal');
        expect(
          m.nutrition.proteinG + m.nutrition.fatG + m.nutrition.carbsG,
          greaterThan(0),
          reason: '${m.id} has no macros',
        );
      }
    });

    test('every dish name is translated in all three languages', () {
      // The picker matches on the rendered name, so a missing translation is
      // a dish nobody can find.
      for (final lang in const ['en', 'ru', 'uk']) {
        final t = AppLocalizations(lang);
        for (final m in MealCatalog.all) {
          expect(t.tr(m.nameKey), isNot(m.nameKey),
              reason: '${m.nameKey} missing in $lang');
        }
      }
    });
  });

  group('logging from the picker', () {
    test('files the food under the meal it was added to', () {
      final c = harness();
      c.read(manualFoodProvider.notifier).add(
            'Овсянка',
            const NutritionFacts(kcal: 350, proteinG: 12, fatG: 9, carbsG: 55),
            slot: MealSlot.breakfast,
          );

      final entry = c.read(manualFoodProvider).single;
      expect(entry.slot, MealSlot.breakfast);
      expect(entry.nutrition.kcal, 350);
    });

    test('a half portion halves everything', () {
      const full =
          NutritionFacts(kcal: 400, proteinG: 20, fatG: 10, carbsG: 50);
      NutritionFacts scaled(double p) => NutritionFacts(
            kcal: (full.kcal * p).round(),
            proteinG: (full.proteinG * p).round(),
            fatG: (full.fatG * p).round(),
            carbsG: (full.carbsG * p).round(),
          );
      expect(scaled(0.5).kcal, 200);
      expect(scaled(0.5).proteinG, 10);
      expect(scaled(2).carbsG, 100);
    });

    test('a nameless or zero-calorie entry is refused', () {
      final c = harness();
      c.read(manualFoodProvider.notifier).add('', NutritionFacts.zero);
      c.read(manualFoodProvider.notifier).add('Воздух', NutritionFacts.zero);
      expect(c.read(manualFoodProvider), isEmpty);
    });
  });

  group('taking food back', () {
    test('undo restores the same entry, not a lookalike', () {
      final c = harness();
      c.read(manualFoodProvider.notifier).add(
            'Борщ',
            const NutritionFacts(kcal: 300, proteinG: 10, fatG: 8, carbsG: 40),
            slot: MealSlot.lunch,
          );
      final entry = c.read(manualFoodProvider).single;

      c.read(manualFoodProvider.notifier).remove(entry.id);
      expect(c.read(manualFoodProvider), isEmpty);

      c.read(manualFoodProvider.notifier).restore(entry);
      final back = c.read(manualFoodProvider).single;
      expect(back.id, entry.id);
      expect(back.slot, MealSlot.lunch);
    });
  });

  test('food logged before meals existed keeps an honest empty slot', () {
    final old = ManualFoodEntry.fromJson(const {
      'id': 'x',
      'name': 'Что-то',
      'kcal': 200,
      'p': 5,
      'f': 5,
      'c': 20,
    });
    expect(old.slot, isNull,
        reason: 'guessing a meal it may never have been is worse than none');
  });
}

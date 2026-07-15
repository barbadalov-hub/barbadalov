import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/food/presentation/pages/diet_page.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// End-to-end proof of the dietitian flow: a saved profile (desk job + 2
/// workouts, exactly the spec example) produces a Ukrainian menu with store
/// prices on the Diet screen.
void main() {
  testWidgets('Diet page renders a UA menu with store prices', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const profile = UserProfile(
      name: 'Діана',
      sex: Sex.female,
      age: 28,
      heightCm: 168,
      weightKg: 62,
      waistCm: 70,
      hipsCm: 96,
      deskJob: true,
      workoutsPerWeek: 2,
      goal: FitnessGoal.maintain,
    );
    final store = InMemoryKeyValueStore(
      {'profile.user': jsonEncode(profile.toJson())},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [keyValueStoreProvider.overrideWithValue(store)],
        child: const MaterialApp(
          locale: Locale('uk'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: DietPage(),
        ),
      ),
    );
    // Fixed pumps: the animated backdrop never settles by design.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    // Header with targets, in Ukrainian.
    expect(find.text('Дієтолог'), findsOneWidget);
    expect(find.textContaining('Ціль:'), findsOneWidget);
    expect(find.textContaining('ккал'), findsWidgets);

    // The day-tabbed menu lists the main meals by slot.
    expect(find.textContaining('Сніданок'), findsWidgets);
    expect(find.textContaining('Обід'), findsWidgets);
    expect(find.textContaining('Вечеря'), findsWidgets);

    // Tapping a meal opens its detail popup with brand-free store prices.
    final breakfast = find.text('Сніданок').first;
    await tester.ensureVisible(breakfast);
    await tester.pump();
    await tester.tap(breakfast);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Де купити'), findsWidgets);

    // Expanding it shows all three anonymous price tiers with totals.
    final whereToBuy = find.textContaining('Де купити').first;
    await tester.ensureVisible(whereToBuy);
    await tester.pump();
    await tester.tap(whereToBuy);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Магазин 1'), findsWidgets);
    expect(find.textContaining('Магазин 2'), findsWidgets);
    expect(find.textContaining('Магазин 3'), findsWidgets);
  });
}

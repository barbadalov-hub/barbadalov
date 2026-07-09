import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/health/presentation/pages/workout_guide_page.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

void main() {
  testWidgets('guide shows personal HR zones, sections and the hard NOs',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const profile = UserProfile(
      name: 'A',
      sex: Sex.male,
      age: 30,
      heightCm: 180,
      weightKg: 80,
    );
    final store = InMemoryKeyValueStore(
      {'profile.user': jsonEncode(profile.toJson())},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [keyValueStoreProvider.overrideWithValue(store)],
        child: const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: WorkoutGuidePage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    // Personal zones from age 30 → max 190; fat-burn zone 114–133 bpm.
    expect(find.textContaining('190'), findsWidgets);
    expect(find.text('114–133 bpm'), findsOneWidget);

    // Key sections and the red list are present in Russian.
    expect(find.textContaining('Разминка — обязательна'), findsOneWidget);
    expect(find.textContaining('Когда тренироваться нельзя'), findsOneWidget);
    expect(find.textContaining('Это делать нельзя'), findsOneWidget);
    expect(
      find.textContaining('без разминки — причина №1'),
      findsOneWidget,
    );

    // Drain the staggered-entrance timers so teardown sees none pending.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  });
}

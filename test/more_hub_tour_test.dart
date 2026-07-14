import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Covers the compact More hub (categories open in a bottom sheet) and the
/// re-openable app tutorial reachable from the hub's top card.
void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(
            InMemoryKeyValueStore({'onboarding.done': 'true'})),
        splashDurationProvider.overrideWithValue(Duration.zero),
      ],
      child: const LifeOsApp(),
    ));
    await settle(tester);
    // Go to the More tab (English locale in tests).
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('More'),
    ));
    await settle(tester);
  }

  testWidgets('More hub groups modules into category sheets', (tester) async {
    await boot(tester);

    // Categories are shown as cards; individual modules are NOT on the page
    // until you open a category (their names only appear inside the sheet).
    expect(find.text('Progress & recaps'), findsOneWidget);
    expect(find.text('Achievements'), findsNothing);

    // Tapping a category opens a sheet listing its modules.
    await tester.tap(find.text('Progress & recaps'));
    await settle(tester);
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('Life timeline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tutorial opens from the More hub and teaches the app',
      (tester) async {
    await boot(tester);

    expect(find.text('How to use Lumo'), findsOneWidget);
    await tester.tap(find.text('How to use Lumo'));
    await settle(tester);

    // First tutorial step is the welcome.
    expect(find.text('Welcome to Lumo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

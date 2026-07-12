import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Navigates through every primary destination and asserts each screen builds
/// without throwing. Complements app_smoke_test (which only lands on Today) and
/// guards the UI layer — the code that never compiled/ran before the build fix.
void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('every primary tab renders without throwing', (tester) async {
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

    // Sanity: we start on Today with the nav bar up.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final label in const ['Money', 'Health', 'Goals', 'More', 'Today']) {
      final target = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      );
      expect(target, findsOneWidget, reason: 'nav destination "$label" missing');
      await tester.tap(target);
      await settle(tester);
      expect(tester.takeException(), isNull,
          reason: 'tapping "$label" threw while building the screen');
      // The shell (and its nav bar) survived the switch.
      expect(find.byType(NavigationBar), findsOneWidget);
    }
  });
}

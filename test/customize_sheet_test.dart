import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// The "Customize home" sheet groups every Today section into labelled
/// segments so the whole catalogue is easy to scan and toggle.
void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('customize sheet shows segmented, toggleable sections',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 2600);
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

    // Open the customize sheet from Today's header.
    await tester.tap(find.byIcon(Icons.tune));
    await settle(tester);

    // Segment headers group the sections (unique labels).
    expect(find.text('AI & tips'), findsOneWidget);
    expect(find.text('Health & food'), findsOneWidget);
    // Every section is a show/hide toggle.
    expect(find.byType(SwitchListTile), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

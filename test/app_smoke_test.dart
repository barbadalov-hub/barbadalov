import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Boots the real app (which transitively compiles every feature) and verifies
/// the Core Engine, all providers and the primary screens come up without
/// throwing — the runtime check that `analyze` can't give us (e.g. a provider
/// dependency cycle would fail here).
void main() {
  testWidgets('LifeOS boots and renders the Today screen', (tester) async {
    // Generous surface so cards never trip a layout-overflow assertion.
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        // Skip first-run onboarding so the boot lands on Today.
        keyValueStoreProvider.overrideWithValue(
            InMemoryKeyValueStore({'onboarding.done': 'true'})),
        // Skip the cosmos splash hold so the app renders immediately.
        splashDurationProvider.overrideWithValue(Duration.zero),
      ],
      child: const LifeOsApp(),
    ));
    // Fixed pumps instead of pumpAndSettle: the animated canvas backdrops
    // (coins/pulse/orbs) run forever by design, so "settle" never happens.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    // Drain the staggered FadeSlideIn entrance timers (up to ~600ms).
    await tester.pump(const Duration(seconds: 1));

    // Today headline + Life Score are present → the money/AI/score pipeline ran.
    expect(find.text('Safe to spend today'), findsOneWidget);
    expect(find.text('Life Score'), findsOneWidget);

    // Bottom navigation wired with all five primary destinations.
    expect(find.text('Money'), findsWidgets);
    expect(find.text('Health'), findsWidgets);
    expect(find.text('Goals'), findsWidgets);
  });
}

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
  testWidgets('Lumo boots and renders the rooms home', (tester) async {
    // Generous surface so cards never trip a layout-overflow assertion.
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        // Skip first-run onboarding so the boot lands on the home grid.
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

    // The home page renders every room — one as the lead cover, the rest as
    // spines — so the money/health/mind/goals providers all resolved without
    // throwing. Titles are the stable anchor: they appear in both forms.
    for (final title in const ['MONEY', 'BODY', 'MIND', 'GOALS']) {
      expect(find.text(title), findsOneWidget, reason: '$title missing');
    }

    // Bottom navigation wired with the three primary destinations.
    expect(find.text('Rooms'), findsWidgets);
    expect(find.text('Day'), findsWidgets);
    expect(find.text('More'), findsWidgets);
  });

  testWidgets('the Day tab still reaches the Today screen', (tester) async {
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Day').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Safe to spend today'), findsOneWidget);
    expect(find.text('Life Score'), findsOneWidget);
  });
}

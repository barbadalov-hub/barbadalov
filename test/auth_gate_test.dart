import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/cloud/presentation/pages/auth_gate_page.dart';
import 'package:lifeos/features/cloud/presentation/providers/cloud_providers.dart';
import 'package:lifeos/features/home/presentation/pages/home_shell.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// The first-run registration gate: when a cloud project is configured, an
/// unregistered user must register before reaching the app; a signed-in user
/// (or an offline build) goes straight through.
void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> pumpApp(WidgetTester tester, List<Override> overrides) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(
            InMemoryKeyValueStore({'onboarding.done': 'true'})),
        splashDurationProvider.overrideWithValue(Duration.zero),
        ...overrides,
      ],
      child: const LifeOsApp(),
    ));
    await settle(tester);
  }

  testWidgets('auth not required (offline build) → straight to the app',
      (tester) async {
    await pumpApp(tester, [authRequiredProvider.overrideWithValue(false)]);
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(AuthGatePage), findsNothing);
  });

  testWidgets('auth required + not signed in → registration gate',
      (tester) async {
    await pumpApp(tester, [authRequiredProvider.overrideWithValue(true)]);
    expect(find.byType(AuthGatePage), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);
  });

  testWidgets('auth required + signed in → app', (tester) async {
    await pumpApp(tester, [
      authRequiredProvider.overrideWithValue(true),
      accountEmailProvider.overrideWith((ref) => 'me@example.com'),
    ]);
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(AuthGatePage), findsNothing);
  });
}

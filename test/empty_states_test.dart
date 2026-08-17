import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/goals/presentation/pages/goals_page.dart';
import 'package:lifeos/features/health/presentation/pages/health_page.dart';
import 'package:lifeos/features/mind/presentation/pages/mind_page.dart';
import 'package:lifeos/features/money/presentation/pages/money_page.dart';
import 'package:lifeos/features/planner/presentation/pages/planner_page.dart';
import 'package:lifeos/features/telescope/presentation/pages/telescope_page.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';

/// A brand-new account is the first thing everyone sees, and it is the state
/// that gets the least attention while building. Each screen must say
/// something useful when it has no data — never leave the newcomer staring at
/// a blank scroll, and never show controls for content that isn't there.
void main() {
  Future<void> open(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        // Nothing logged, nothing configured: a fresh install.
        keyValueStoreProvider.overrideWithValue(
            InMemoryKeyValueStore({'onboarding.done': 'true'})),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: screen,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('Money greets an empty account instead of a blank list',
      (tester) async {
    await open(tester, const MoneyPage());
    expect(find.textContaining('No transactions yet'), findsOneWidget);
    // ...and does not offer to search or filter nothing. Targeted at the
    // search field itself rather than "any TextField": the room legitimately
    // has one for the affordability check, which works on an empty account.
    expect(find.text('Search transactions…'), findsNothing,
        reason: 'the history search should be hidden until there is history');
  });

  testWidgets('Goals invites a first goal', (tester) async {
    await open(tester, const GoalsPage());
    expect(find.textContaining('No goals yet'), findsOneWidget);
  });

  testWidgets('Mind invites a first habit', (tester) async {
    await open(tester, const MindPage());
    expect(find.textContaining('No habits yet'), findsOneWidget);
  });

  testWidgets('Body explains what to log first', (tester) async {
    await open(tester, const HealthPage());
    expect(find.textContaining('Nothing logged yet today'), findsOneWidget);
  });

  testWidgets('the planner explains what a plan is for', (tester) async {
    await open(tester, const PlannerPage());
    expect(find.textContaining('Nothing planned yet'), findsOneWidget);
  });

  testWidgets('the telescope says the window is empty', (tester) async {
    await open(tester, const TelescopePage());
    expect(find.textContaining('Nothing logged in this window'), findsOneWidget);
  });
}

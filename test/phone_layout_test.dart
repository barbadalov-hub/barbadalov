import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/goals/presentation/pages/goals_page.dart';
import 'package:lifeos/features/health/presentation/pages/health_page.dart';
import 'package:lifeos/features/home/presentation/pages/today_page.dart';
import 'package:lifeos/features/mind/presentation/pages/mind_page.dart';
import 'package:lifeos/features/money/presentation/pages/money_page.dart';
import 'package:lifeos/features/planner/presentation/pages/planner_page.dart';
import 'package:lifeos/features/rooms/presentation/pages/rooms_page.dart';
import 'package:lifeos/features/telescope/presentation/pages/telescope_page.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';

/// Every screen, rendered at a real phone width in Russian — the widest labels
/// the app ships. Flutter reports a layout overflow as an exception, so this
/// catches the stripes automatically instead of leaving them to be spotted in a
/// screenshot (which is how the planner's header overflow was found).
///
/// The rest of the suite renders at 1400px wide, where nothing ever overflows.
void main() {
  const screens = <String, Widget>{
    'rooms': RoomsPage(),
    'today': TodayPage(),
    'telescope': TelescopePage(),
    'planner': PlannerPage(),
    'money': MoneyPage(),
    'body': HealthPage(),
    'mind': MindPage(),
    'goals': GoalsPage(),
  };

  /// Renders one screen at phone size and returns whatever it threw.
  ///
  /// Scrolling matters: these screens are lazy slivers, so a child below the
  /// fold is never laid out and never gets the chance to overflow. The books
  /// header on Mind hid behind exactly that blind spot.
  Future<Object?> render(
    WidgetTester tester,
    Widget screen, {
    required Brightness brightness,
    double textScale = 1.0,
  }) async {
    // iPhone-ish logical size; the narrowest mainstream phone is 360.
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(
            InMemoryKeyValueStore({'onboarding.done': 'true'})),
      ],
      child: MaterialApp(
        // Russian: ~20% longer than English, so it is the honest stress test.
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme:
            brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: textScale,
          maxScaleFactor: textScale,
          child: child!,
        ),
        home: screen,
      ),
    ));

    // Fixed pumps: the animated backdrops repeat forever, so settle never
    // happens. Overflows surface during layout on the first frames.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
    final onFirstScreen = tester.takeException();
    if (onFirstScreen != null) return onFirstScreen;

    // Walk down the page so everything below the fold gets laid out too.
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isEmpty) return null;
    for (var screenful = 0; screenful < 12; screenful++) {
      await tester.drag(scrollable.first, const Offset(0, -600),
          warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final thrown = tester.takeException();
      if (thrown != null) return thrown;
    }
    return null;
  }

  // Accessibility: someone who has turned system text up should still be able
  // to use the app, not just see it clip. 1.5x is a common setting.
  for (final entry in screens.entries) {
    testWidgets('${entry.key} survives 1.5x system text', (tester) async {
      expect(
        await render(tester, entry.value,
            brightness: Brightness.light, textScale: 1.5),
        isNull,
        reason: '${entry.key} breaks when system text is enlarged',
      );
    });
  }

  for (final entry in screens.entries) {
    for (final brightness in Brightness.values) {
      testWidgets('${entry.key} fits a phone in ${brightness.name}',
          (tester) async {
        expect(
          await render(tester, entry.value, brightness: brightness),
          isNull,
          reason: '${entry.key} overflows or throws at 360px wide',
        );
      });
    }
  }
}

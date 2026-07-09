import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/achievements/presentation/pages/achievements_page.dart';
import 'package:lifeos/features/coach/presentation/pages/coach_page.dart';
import 'package:lifeos/features/insights/domain/insight_engine.dart';
import 'package:lifeos/features/insights/domain/mood_patterns.dart';
import 'package:lifeos/features/insights/presentation/pages/insights_page.dart';
import 'package:lifeos/features/insights/presentation/providers/insights_providers.dart';
import 'package:lifeos/features/mind/domain/mood.dart';
import 'package:lifeos/features/wrapped/domain/wrapped_stats.dart';
import 'package:lifeos/features/wrapped/presentation/pages/wrapped_page.dart';
import 'package:lifeos/features/wrapped/presentation/providers/wrapped_providers.dart';

/// Wraps a page in the localization + provider scaffolding, pinned to English.
Widget _wrap(Widget page, {List<Override> overrides = const []}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    );

void main() {
  void bigSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Achievements wall renders the hero count and locked badges',
      (tester) async {
    bigSurface(tester);
    await tester.pumpWidget(_wrap(const AchievementsPage()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // AppBar title + hero share the localized "Achievements" label.
    expect(find.text('Achievements'), findsWidgets);
    // The hero shows the "N of M unlocked" progress line.
    expect(find.textContaining('unlocked'), findsOneWidget);
    // A category header and a known badge from the catalog are on the wall.
    expect(find.text('Habits'), findsWidgets);
    expect(find.text('First step'), findsOneWidget);
  });

  testWidgets('Coach greets, then answers a tapped suggestion', (tester) async {
    bigSurface(tester);
    await tester.pumpWidget(_wrap(const CoachPage()));
    await tester.pump(); // first build
    await tester.pump(const Duration(milliseconds: 150)); // post-frame greeting

    // The greeting bubble is present.
    expect(find.textContaining('AI coach'), findsOneWidget);

    // Tap the "How is my sleep?" suggestion chip.
    final sleepChip = find.widgetWithText(ActionChip, 'How is my sleep?');
    expect(sleepChip, findsOneWidget);
    await tester.ensureVisible(sleepChip);
    await tester.tap(sleepChip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    // The user's question echoes and the coach answers about sleep (no data →
    // the "log your sleep" nudge), so several sleep-mentioning texts exist.
    expect(find.textContaining('sleep'), findsWidgets);
  });

  testWidgets('Insights shows the empty state with no data', (tester) async {
    bigSurface(tester);
    await tester.pumpWidget(_wrap(
      const InsightsPage(),
      // Force a truly empty dataset (a fresh store seeds demo habits/streaks).
      overrides: [insightsProvider.overrideWithValue(const InsightsData())],
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Patterns in your life'), findsOneWidget); // hero
    expect(find.text('Nothing to show yet'), findsOneWidget); // empty state
    // No data → no share affordance.
    expect(find.byIcon(Icons.ios_share), findsNothing);
  });

  testWidgets('Insights renders correlations, patterns and share when seeded',
      (tester) async {
    bigSurface(tester);
    const data = InsightsData(
      correlations: [
        LifeInsight(driver: InsightDriver.sleep, corr: 0.7, samples: 10),
      ],
      trackedDays: 12,
      bestStreak: 5,
      loggingStreak: 4,
      bestWeekday: WeekdayMood(DateTime.saturday, 4.5, 3),
      trend: MoodTrend.rising,
      activityImpacts: [MoodCorrelation('friends', 0.8, 5)],
    );
    await tester.pumpWidget(_wrap(
      const InsightsPage(),
      overrides: [insightsProvider.overrideWithValue(data)],
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // The sleep→mood correlation sentence.
    expect(find.textContaining('sleep more'), findsOneWidget);
    // Mood-patterns section + the rising-trend line.
    expect(find.text('Mood patterns'), findsWidgets);
    expect(find.textContaining('trending up'), findsOneWidget);
    // Data present → the share button appears.
    expect(find.byIcon(Icons.ios_share), findsOneWidget);
  });

  testWidgets('Wrapped intro renders the selected year', (tester) async {
    bigSurface(tester);
    const stats = WrappedStats(
      year: 2026,
      monthsTracked: 3,
      incomeMinor: 100000,
      spentMinor: 40000,
    );
    await tester.pumpWidget(_wrap(
      const WrappedPage(),
      overrides: [
        wrappedProvider.overrideWithValue(stats),
        wrappedAvailableYearsProvider.overrideWithValue(const [2026]),
        wrappedYearProvider.overrideWith((ref) => 2026),
      ],
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('2026'), findsWidgets);
  });
}

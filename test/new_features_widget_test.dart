import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/features/health/presentation/pages/workouts_page.dart';
import 'package:lifeos/features/money/presentation/pages/money_page.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Fixed "now" so date-dependent seeds/verdicts don't drift with the calendar.
class _FixedClock implements Clock {
  final DateTime _t;
  const _FixedClock(this._t);
  @override
  DateTime now() => _t;
}

Widget _app(Widget home, {List<Override> overrides = const []}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('uk'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

void main() {
  setUp(() {
    // Tall viewport so long list screens lay out without overflow.
  });

  testWidgets('Workouts page renders catalog with technique and sets',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(const WorkoutsPage()));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Тренування'), findsOneWidget);
    expect(find.text('Присідання'), findsOneWidget);
    expect(find.text('4 × 12'), findsOneWidget);
    expect(find.text('Станова тяга з гирею'), findsOneWidget);

    // Open details: steps + video + done actions are there.
    await tester.tap(find.text('Присідання'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Стопи на ширині плечей'), findsOneWidget);
    expect(find.text('Відео'), findsOneWidget);
    expect(find.text('Виконано ✓'), findsOneWidget);
  });

  testWidgets('Money page shows the smart-finance verdicts', (tester) async {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Pin "now" to early in the month so the seeded spend (1090 of a 3200
    // income) reads as an over-pace regardless of today's calendar date.
    await tester.pumpWidget(_app(
      const MoneyPage(),
      overrides: [
        clockProvider.overrideWithValue(_FixedClock(DateTime(2026, 3, 5))),
      ],
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // Seeded month: 1090 spent in the first days of a 3200-income month →
    // the analyzer must warn about pace and month-end projection.
    expect(find.textContaining('Розумні фінанси'), findsOneWidget);
    expect(find.text('Витрачаєте швидше за план'), findsOneWidget);
    expect(find.text('Прогноз: перевитрата до кінця місяця'), findsOneWidget);
    expect(find.text('Де себе обмежити'), findsOneWidget);
  });
}

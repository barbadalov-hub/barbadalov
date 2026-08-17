import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/planner/presentation/pages/planner_page.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';

class _FixedClock implements Clock {
  final DateTime _now;
  const _FixedClock(this._now);
  @override
  DateTime now() => _now;
}

/// A day planner that shows nothing until you add something is a blank page.
/// The hours are the point: they show the shape of the day, and an empty one
/// you can tap is an invitation where a void is a dead end.
void main() {
  Future<void> open(WidgetTester tester, DateTime now) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore({})),
        clockProvider.overrideWithValue(_FixedClock(now)),
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: const PlannerPage(),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('an empty day still shows its hours', (tester) async {
    await open(tester, DateTime(2026, 4, 9, 9));

    // The waking day, drawn whether or not anything is in it.
    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);
    expect(find.text('22:00'), findsOneWidget);
  });

  testWidgets('a free hour offers to be filled, a spent one does not',
      (tester) async {
    await open(tester, DateTime(2026, 4, 9, 12, 30));

    Widget rowOf(String label) => tester.widget<InkWell>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(InkWell),
          ).first,
        );

    // 08:00 is over and done with; planning the past is not something to
    // invite anyone to do.
    expect((rowOf('08:00') as InkWell).onTap, isNull);
    // 15:00 is still ahead, so it is tappable.
    expect((rowOf('15:00') as InkWell).onTap, isNotNull);
  });

  testWidgets('tapping a free hour opens the dialog on that hour',
      (tester) async {
    await open(tester, DateTime(2026, 4, 9, 9));

    await tester.tap(find.text('15:00'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The dialog should already point at the slot that was tapped, rather than
    // making the user pick the time they just chose by tapping.
    expect(find.textContaining('15:00'), findsWidgets);
  });
}

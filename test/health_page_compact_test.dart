import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/health/presentation/pages/health_page.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

class _FixedClock implements Clock {
  @override
  DateTime now() => DateTime(2026, 3, 5, 10);
}

Widget _host(Widget page) => ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(
            InMemoryKeyValueStore({'onboarding.done': 'true'})),
        clockProvider.overrideWithValue(_FixedClock()),
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

  testWidgets('Health screen shows the two compact detail entries',
      (tester) async {
    bigSurface(tester);
    await tester.pumpWidget(_host(const HealthPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Body & vitals'), findsOneWidget);
    expect(find.text('Trends'), findsOneWidget);
    // Detail widgets are hidden until an entry is tapped — they live in popups.
    expect(find.text('Heart rate'), findsNothing);
  });

  testWidgets('Tapping "Body & vitals" opens the metrics popup',
      (tester) async {
    bigSurface(tester);
    await tester.pumpWidget(_host(const HealthPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Body & vitals'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The grouped metrics (heart rate, stress) now show inside the sheet.
    expect(find.text('Heart rate'), findsOneWidget);
    expect(find.text('Stress level'), findsOneWidget);
  });

  testWidgets('Tapping "Trends" opens the weekly-charts popup', (tester) async {
    bigSurface(tester);
    await tester.pumpWidget(_host(const HealthPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Trends'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The popup's own title appears (headline inside the sheet).
    expect(find.text('Trends'), findsWidgets);
  });
}

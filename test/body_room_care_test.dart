import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/health/domain/daily_motivation.dart';
import 'package:lifeos/features/health/presentation/pages/health_page.dart';
import 'package:lifeos/features/reminders/domain/entities/reminder.dart';
import 'package:lifeos/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';

class _FixedClock implements Clock {
  final DateTime _now;
  const _FixedClock(this._now);
  @override
  DateTime now() => _now;
}

void main() {
  late ProviderContainer container;

  Future<void> open(WidgetTester tester, DateTime now) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    container = ProviderContainer(overrides: [
      keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore({})),
      clockProvider.overrideWithValue(_FixedClock(now)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
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
        home: const HealthPage(),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('the day line shows the right part of the day', (tester) async {
    final evening = DateTime(2026, 4, 9, 20, 30);
    await open(tester, evening);

    const t = AppLocalizations('ru');
    expect(find.text(t.tr('motiv.part.evening').toUpperCase()), findsOneWidget);
    expect(
      find.text(t.tr(DailyMotivation.keyFor(evening, DayPart.evening))),
      findsOneWidget,
    );
    // ...and not the morning's line, which is a different sentence entirely.
    expect(
      find.text(t.tr(DailyMotivation.keyFor(evening, DayPart.morning))),
      findsNothing,
    );
  });

  testWidgets('one tap arms a care reminder and another takes it away',
      (tester) async {
    await open(tester, DateTime(2026, 4, 9, 10));

    const water = ValueKey('care.water');
    expect(find.byKey(water), findsOneWidget,
        reason: 'the care shelf offers water');
    expect(container.read(remindersProvider), isEmpty);

    await tester.tap(find.byKey(water));
    await tester.pump();

    final armed = container.read(remindersProvider);
    expect(armed.length, 1);
    expect(armed.single.kind, ReminderKind.water);
    // Water arrives repeating: a single daily ping would not change a day.
    expect(armed.single.repeats, isTrue);
    expect(armed.single.occurrences.length, greaterThan(1));

    await tester.tap(find.byKey(water));
    await tester.pump();
    expect(container.read(remindersProvider), isEmpty);
  });

  testWidgets('the shelf says what each reminder would do before it is on',
      (tester) async {
    await open(tester, DateTime(2026, 4, 9, 10));

    const t = AppLocalizations('ru');
    // Medication is a fixed time; movement repeats. Both must advertise which
    // they are while still switched off.
    expect(
      find.text('${ReminderKind.meds.defaultHour.toString().padLeft(2, '0')}:00'),
      findsOneWidget,
    );
    expect(
      find.text(t.trp('care.every', {'h': '1.5'})),
      findsWidgets,
      reason: 'the 90-minute kinds should read as "every 1.5 h"',
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/health/domain/entities/activity_entry.dart';
import 'package:lifeos/features/health/presentation/pages/health_page.dart';
import 'package:lifeos/features/health/presentation/providers/activity_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';

class _FixedClock implements Clock {
  final DateTime _now;
  const _FixedClock(this._now);
  @override
  DateTime now() => _now;
}

void main() {
  final now = DateTime(2026, 8, 18, 19);

  ProviderContainer harness() {
    final c = ProviderContainer(overrides: [
      keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore({})),
      clockProvider.overrideWithValue(_FixedClock(now)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('logging a session', () {
    test('records the kind and how long it ran', () {
      final c = harness();
      c.read(activitiesProvider.notifier).add(ActivityKind.gym, 45);

      final today = c.read(todayActivitiesProvider);
      expect(today, hasLength(1));
      expect(today.single.kind, ActivityKind.gym);
      expect(today.single.minutes, 45);
      expect(c.read(todayActiveMinutesProvider), 45);
    });

    test('minutes add up across sessions', () {
      final c = harness();
      c.read(activitiesProvider.notifier)
        ..add(ActivityKind.walk, 20)
        ..add(ActivityKind.run, 30);
      expect(c.read(todayActiveMinutesProvider), 50);
    });

    test('yesterday does not count towards today', () {
      final c = harness();
      c.read(activitiesProvider.notifier).add(ActivityKind.run, 30,
          at: now.subtract(const Duration(days: 1)));
      expect(c.read(todayActivitiesProvider), isEmpty);
      expect(c.read(activitiesProvider), hasLength(1),
          reason: 'it still happened, it is just not today');
    });
  });

  group('taking one back', () {
    test('removing drops exactly the one asked for', () {
      final c = harness();
      final gym = c.read(activitiesProvider.notifier).add(ActivityKind.gym, 60);
      c.read(activitiesProvider.notifier).add(ActivityKind.walk, 15);

      c.read(activitiesProvider.notifier).remove(gym.id);

      final left = c.read(todayActivitiesProvider);
      expect(left, hasLength(1));
      expect(left.single.kind, ActivityKind.walk);
    });

    test('undo puts back the same entry, not a lookalike', () {
      final c = harness();
      final entry =
          c.read(activitiesProvider.notifier).add(ActivityKind.swim, 40);
      c.read(activitiesProvider.notifier).remove(entry.id);
      c.read(activitiesProvider.notifier).restore(entry);

      final back = c.read(todayActivitiesProvider).single;
      expect(back.id, entry.id, reason: 'restored, not recreated');
      expect(back.at, entry.at);
      expect(back.minutes, 40);
    });

    test('restoring twice does not duplicate', () {
      final c = harness();
      final entry =
          c.read(activitiesProvider.notifier).add(ActivityKind.yoga, 30);
      c.read(activitiesProvider.notifier)
        ..remove(entry.id)
        ..restore(entry)
        ..restore(entry);
      expect(c.read(todayActivitiesProvider), hasLength(1));
    });
  });

  testWidgets('the room lists today and offers to remove a session',
      (tester) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = harness();
    c.read(activitiesProvider.notifier).add(ActivityKind.gym, 45);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
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

    const t = AppLocalizations('ru');
    expect(find.text(t.tr('act.gym')), findsOneWidget);
    expect(find.text(t.trp('act.todayTotal', {'n': 45})), findsOneWidget);

    await tester.tap(find.byTooltip(t.tr('common.delete')));
    await tester.pump();

    expect(c.read(todayActivitiesProvider), isEmpty);
    // Removing is itself a tap that can be wrong, so it comes back offered.
    expect(find.text(t.tr('common.undo')), findsOneWidget);
  });
}

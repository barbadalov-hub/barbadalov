import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/rooms/domain/life_room.dart';
import 'package:lifeos/features/rooms/presentation/pages/rooms_page.dart';
import 'package:lifeos/features/rooms/presentation/providers/rooms_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';

void main() {
  group('formatSteps', () {
    test('keeps small counts exact and abbreviates thousands', () {
      expect(formatSteps(0), '0');
      expect(formatSteps(940), '940');
      expect(formatSteps(7420), '7.4k');
      expect(formatSteps(12300), '12k');
    });
  });

  group('splitHours', () {
    test('splits decimal hours into hours and minutes', () {
      expect(splitHours(6.5), (hours: 6, minutes: 30));
      expect(splitHours(0), (hours: 0, minutes: 0));
      expect(splitHours(8), (hours: 8, minutes: 0));
    });
  });

  group('room catalog', () {
    test('has exactly the four Life Score pillars, no duplicates', () {
      expect(kLifeRooms.length, 4);
      expect(kLifeRooms.map((r) => r.id).toSet(), RoomId.values.toSet());
    });

    test('each room resolves a different colour per skin', () {
      for (final room in kLifeRooms) {
        expect(room.colorFor(Brightness.light), room.paper);
        expect(room.colorFor(Brightness.dark), room.night);
        expect(room.paper, isNot(room.night),
            reason: '${room.id} must adapt to the skin');
      }
    });

    test('roomById finds every room', () {
      for (final id in RoomId.values) {
        expect(roomById(id).id, id);
      }
    });
  });

  group('summaries', () {
    ProviderContainer container() => ProviderContainer(overrides: [
          keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore({})),
        ]);

    test('produce one entry per room, in catalog order', () {
      final c = container();
      addTearDown(c.dispose);
      final s = c.read(roomSummariesProvider);
      expect(s.length, kLifeRooms.length);
      expect(s.map((e) => e.id).toList(),
          kLifeRooms.map((r) => r.id).toList());
    });

    test('an empty account shows placeholders, never a crash', () {
      final c = container();
      addTearDown(c.dispose);
      final byId = {for (final s in c.read(roomSummariesProvider)) s.id: s};
      expect(byId[RoomId.mind]!.hero, '—');
      expect(byId[RoomId.goals]!.hero, '—');
      expect(byId[RoomId.goals]!.subtitleKey, 'room.goals.subNone');
      // Steps still render as a number even with nothing logged.
      expect(byId[RoomId.body]!.hero, '0');
    });
  });

  testWidgets('home renders four rooms and the score on the seam',
      (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    RoomId? tapped;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore({})),
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
        home: RoomsPage(onOpenRoom: (r) => tapped = r),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Every room's subtitle is on screen, and the score badge with it.
    expect(find.text('left to spend today'), findsOneWidget);
    expect(find.text('habits kept today'), findsOneWidget);
    expect(find.text('score'), findsOneWidget);

    // Tapping a room reports which one, without navigating itself.
    await tester.tap(find.text('left to spend today'));
    await tester.pump();
    expect(tapped, RoomId.money);
  });
}

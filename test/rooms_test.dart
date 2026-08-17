import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/rooms/domain/life_room.dart';
import 'package:lifeos/features/rooms/domain/room_attention.dart';
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

  group('the front page', () {
    /// The lead is stubbed rather than provoked with data: which room wins is
    /// [RoomAttentionBuilder]'s job and is covered exhaustively in
    /// room_attention_test. Here we only care what the page does with it.
    Future<void> pump(
      WidgetTester tester,
      RoomAttention? lead, {
      void Function(RoomId room)? onOpenRoom,
    }) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore({})),
          roomAttentionProvider.overrideWithValue(lead),
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
          home: RoomsPage(onOpenRoom: onOpenRoom),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('runs a lead cover for the room that needs you',
        (tester) async {
      await pump(
        tester,
        const RoomAttention(
          room: RoomId.body,
          urgency: 78,
          reasonKey: 'attn.body.blank',
          action: AttentionAction.openRoom,
          actionKey: 'attn.body.blankAction',
        ),
      );

      // The headline and its single offer.
      expect(find.textContaining('Nothing logged today'), findsOneWidget);
      expect(find.text('Log the day'), findsOneWidget);

      // All four rooms are still reachable: one leads, three are spines.
      for (final title in const ['MONEY', 'BODY', 'MIND', 'GOALS']) {
        expect(find.text(title), findsOneWidget, reason: '$title missing');
      }
      // The score keeps a home even when the cover is a room.
      expect(find.byTooltip('Life score'), findsOneWidget);
    });

    testWidgets('a calm day has no headline at all', (tester) async {
      await pump(tester, null);

      expect(find.textContaining('you owe nobody anything'), findsOneWidget);
      expect(find.text('LIFE SCORE'), findsOneWidget);
      // Nothing leads, so every room sits in the rack.
      for (final title in const ['MONEY', 'BODY', 'MIND', 'GOALS']) {
        expect(find.text(title), findsOneWidget, reason: '$title missing');
      }
    });

    testWidgets('both a cover and a spine open their own room',
        (tester) async {
      const lead = RoomAttention(
        room: RoomId.body,
        urgency: 78,
        reasonKey: 'attn.body.blank',
        action: AttentionAction.openRoom,
        actionKey: 'attn.body.blankAction',
      );

      final opened = <RoomId>[];
      await pump(tester, lead, onOpenRoom: opened.add);

      await tester.tap(find.text('BODY')); // the lead cover
      await tester.pump();
      await tester.tap(find.text('MONEY')); // a spine
      await tester.pump();

      expect(opened, [RoomId.body, RoomId.money]);
    });

    testWidgets('the cover offer acts without leaving the page',
        (tester) async {
      // Water is the one reason a single tap genuinely fixes, so the chip must
      // log it here rather than dumping the user into the body room.
      final opened = <RoomId>[];
      await pump(
        tester,
        const RoomAttention(
          room: RoomId.body,
          urgency: 52,
          reasonKey: 'attn.body.water',
          action: AttentionAction.drinkGlass,
          actionKey: 'attn.body.waterAction',
        ),
        onOpenRoom: opened.add,
      );

      await tester.tap(find.text('+ a glass'));
      await tester.pump();

      expect(opened, isEmpty, reason: 'a one-tap fix must not navigate');
      expect(find.text('A glass of water logged'), findsOneWidget);
    });
  });
}

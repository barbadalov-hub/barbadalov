import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter/rendering.dart';
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

/// Design tool, not a test — the filename has no `_test` suffix so the suite
/// never picks it up.
///
///   flutter test test/capture_skin.dart
///
/// It writes `build/skin/today_{paper,night}.png` so the design can be looked
/// at when there is no display to screenshot. **It does not terminate**: the
/// PNGs are written early, then the run hangs (the real page boots the whole
/// provider graph — repeating animations, HTTP clients, background services —
/// and `toImage` never lets go). Give it ~40s, kill it, read the PNGs. Keeping
/// it out of `test/` guarantees that hang can never eat a CI run.
void main() {
  /// The test renderer ships no fonts, so every glyph comes out as a tofu box
  /// and the design cannot actually be judged. Load the ones the app already
  /// bundles for web.
  /// Must run inside [WidgetTester.runAsync]: reading the files is real I/O,
  /// and a widget test's fake clock never completes it otherwise — the run just
  /// hangs with no error.
  Future<void> loadFonts(WidgetTester tester) => tester.runAsync(() async {
    // The bundled Roboto is a Latin subset — the app pairs it with NotoSans for
    // Cyrillic via fontFamilyFallback, but that is web-only, so in tests every
    // Russian glyph would still come out as tofu. Registering NotoSans *as*
    // Roboto gives the renderer one family that covers the whole UI.
    // MaterialIcons ships with the SDK rather than the app, and without it
    // every icon photographs as an empty square — which is worthless when the
    // point of the shot is judging a cover whose illustration IS an icon.
    const sdkIcons = r'C:\src\flutter\bin\cache\artifacts\material_fonts'
        r'\MaterialIcons-Regular.otf';
    for (final entry in {
      'Roboto': const ['assets/fonts/NotoSans.ttf'],
      'RobotoWeb': const ['assets/fonts/NotoSans.ttf'],
      if (File(sdkIcons).existsSync()) 'MaterialIcons': [sdkIcons],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final path in entry.value) {
        loader.addFont(
          File(path).readAsBytes().then((b) => ByteData.view(b.buffer)),
        );
      }
      await loader.load();
    }
  });

  /// Realistic figures, injected rather than seeded: the repositories load from
  /// storage and an empty account would photograph as a wall of zeroes, which
  /// says nothing about how the design actually reads.
  final livedIn = <RoomSummary>[
    const RoomSummary(
        id: RoomId.money, hero: '12 400 ₽', subtitleKey: 'room.money.sub'),
    const RoomSummary(
      id: RoomId.body,
      hero: '7.4k',
      subtitleKey: 'room.body.sub',
      params: {'h': 6, 'm': 30},
    ),
    const RoomSummary(
        id: RoomId.mind, hero: '4/5', subtitleKey: 'room.mind.sub'),
    const RoomSummary(
        id: RoomId.goals, hero: '62%', subtitleKey: 'room.goals.sub'),
  ];

  Future<void> capture(
    WidgetTester tester,
    Brightness b,
    String name, {
    required RoomAttention? lead,
  }) async {
    await loadFonts(tester);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        keyValueStoreProvider
            .overrideWithValue(InMemoryKeyValueStore({'onboarding.done': 'true'})),
        roomSummariesProvider.overrideWithValue(livedIn),
        roomAttentionProvider.overrideWithValue(lead),
      ],
      // The backdrop drives a forever-repeating AnimationController. Left
      // running it keeps the test alive until the 10-minute timeout (the PNG is
      // already written by then, so the hang looks like a pass). Freezing every
      // ticker in the subtree renders the first frame statically instead.
      child: TickerMode(
        enabled: false,
        child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ru'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          // The app leaves the font family null off the web so each platform
          // uses its own system face. In the test renderer "null" means a stub
          // font of empty squares, and only the styles inherited from Material
          // (which hard-code Roboto) came out readable — half the screen was
          // tofu. Pinning the loaded family across the whole theme is a
          // harness concern only; the shipped app is untouched.
          theme: () {
            final t = b == Brightness.dark ? AppTheme.dark() : AppTheme.light();
            return t.copyWith(
                textTheme: t.textTheme.apply(fontFamily: 'Roboto'));
          }(),
          home: const RoomsPage(),
        ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));

    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('build/skin')..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());

    // The backdrop animation repeats forever; without tearing the tree down the
    // test would sit on those pending timers until the 10-minute timeout (the
    // PNG is already written by then, so the hang is easy to miss).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  // A short night is the most common real lead, and the one whose headline and
  // hero figure have to agree.
  const shortNight = RoomAttention(
    room: RoomId.body,
    urgency: 78,
    reasonKey: 'attn.body.sleep',
    params: {'h': '6.5'},
    heroKey: 'attn.hero.sleep',
    heroParams: {'h': '6.5'},
    action: AttentionAction.openRoom,
    actionKey: 'attn.body.sleepAction',
  );

  for (final skin in const {
    'paper': Brightness.light,
    'night': Brightness.dark,
  }.entries) {
    testWidgets('home leads a story in the ${skin.key} skin', (t) async {
      await capture(t, skin.value, 'lead_${skin.key}', lead: shortNight);
      expect(File('build/skin/lead_${skin.key}.png').lengthSync(),
          greaterThan(1000));
    });

    testWidgets('home on a calm day in the ${skin.key} skin', (t) async {
      await capture(t, skin.value, 'calm_${skin.key}', lead: null);
      expect(File('build/skin/calm_${skin.key}.png').lengthSync(),
          greaterThan(1000));
    });
  }
}

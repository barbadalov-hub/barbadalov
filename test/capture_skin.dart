import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/telescope/presentation/pages/telescope_page.dart';
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
  Future<void> capture(WidgetTester tester, Brightness b, String name) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        keyValueStoreProvider
            .overrideWithValue(InMemoryKeyValueStore({'onboarding.done': 'true'})),
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
          theme: b == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
          home: const TelescopePage(),
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

  testWidgets('home renders in the paper skin', (t) async {
    await capture(t, Brightness.light, 'today_paper');
    expect(File('build/skin/today_paper.png').lengthSync(), greaterThan(1000));
  });

  testWidgets('home renders in the night skin', (t) async {
    await capture(t, Brightness.dark, 'today_night');
    expect(File('build/skin/today_night.png').lengthSync(), greaterThan(1000));
  });
}

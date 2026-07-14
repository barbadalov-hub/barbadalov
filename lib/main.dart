import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/app.dart';
import 'package:lifeos/core/services/notification_gateway.dart';
import 'package:lifeos/core/services/persistent_store.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Surfaces the bundled font licenses (Apache-2.0 / OFL-1.1 / Bitstream Vera)
/// in the built-in `showLicensePage`, so the OSS attribution the fonts require
/// is one tap away from More → Open source licenses.
void _registerBundledFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    const files = <String, List<String>>{
      'assets/licenses/Roboto-Apache-2.0.txt': ['Roboto'],
      'assets/licenses/NotoFonts-OFL-1.1.txt': ['Noto Sans', 'Noto Color Emoji'],
      'assets/licenses/DejaVu.txt': ['DejaVu (symbols)'],
    };
    for (final e in files.entries) {
      yield LicenseEntryWithLineBreaks(e.value, await rootBundle.loadString(e.key));
    }
  });
}

/// Entry point.
///
/// Initialises plugin-free local persistence (a JSON file on desktop/mobile,
/// `localStorage` on web), then overrides [keyValueStoreProvider] so
/// MoneyOS/Food/Health/Mind/Goals survive restarts. Tests keep the ephemeral
/// in-memory default.
///
/// Phase 3 adds `await Firebase.initializeApp(...)` here once `flutterfire
/// configure` has generated `firebase_options.dart`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerBundledFontLicenses();
  final store = await createPersistentStore();
  // Set up OS notifications on phones (no-op on web/desktop). Fire-and-forget
  // so a slow permission prompt never delays first paint.
  unawaited(notificationGateway.init());
  runApp(
    ProviderScope(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
      child: const LifeOsApp(),
    ),
  );
}

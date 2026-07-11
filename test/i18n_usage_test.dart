import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';

/// Guards against the "raw key leaks into the UI" bug: every statically written
/// `context.tr('x')` / `trp('x', …)` literal must resolve to a real entry in
/// the localization table. (Dynamically built keys — `tr('cat.$id')` — can't be
/// checked here and are exercised by their own feature tests.)
void main() {
  test('every literal tr/trp key exists in the localization table', () {
    final defined = AppLocalizations.values.keys.toSet();
    final keyPattern = RegExp(r"\btrp?\(\s*'([\w.]+)'");

    final missing = <String, String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // The table file declares keys, it doesn't consume them.
      if (entity.path.endsWith('app_localizations.dart')) continue;
      final src = entity.readAsStringSync();
      for (final m in keyPattern.allMatches(src)) {
        final key = m.group(1)!;
        if (!defined.contains(key)) {
          missing.putIfAbsent(key, () => entity.path);
        }
      }
    }

    expect(
      missing,
      isEmpty,
      reason: 'Localization keys used in code but missing from the table:\n'
          '${missing.entries.map((e) => '  ${e.key}  (${e.value})').join('\n')}',
    );
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hexes that must never appear in the source again.
///
/// The first two are the colours the contrast fix replaced: amber `F5A623`
/// scored 1.8 against the paper page and green `2E9E6B` scored 2.99, both under
/// the 3.0 line. Fixing `LifeColors` was not enough — twenty-odd screens had
/// pasted the literals instead of using the palette, so they kept the
/// unreadable values while `theme_contrast_test` happily passed. The blue was
/// never in the palette at all and was bright enough to disappear on cream.
const _banned = <String, String>{
  '0xFFF5A623': 'LifeColors.warning',
  '0xFF2E9E6B': 'LifeColors.positive',
  '0xFF3BA7FF': 'LifeColors.info',
};

/// A palette guard is only as good as its reach: a constant that half the app
/// bypasses guards nothing. This is the other half of `theme_contrast_test` —
/// that one proves the palette is legible, this one proves the app uses it.
void main() {
  test('no screen paints with a retired colour literal', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // The palette itself is where colours are allowed to be literals.
      if (entity.path.replaceAll(r'\', '/').endsWith('shared/theme/app_theme.dart')) {
        continue;
      }

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final entry in _banned.entries) {
          if (lines[i].contains(entry.key)) {
            offenders.add(
                '${entity.path}:${i + 1} uses ${entry.key} — use ${entry.value}');
          }
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'retired colours are back in the source:\n'
            '${offenders.join('\n')}');
  });
}

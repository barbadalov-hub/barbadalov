import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/constants/app_constants.dart';

/// Guards the rebrand: user-visible surfaces must all carry the current brand.
/// A rename that misses one spot (as happened with the share-card wordmark)
/// fails here instead of shipping half-rebranded screenshots.
void main() {
  const brand = AppConstants.appName;

  test('brandSlug is the lowercase app name', () {
    expect(AppConstants.brandSlug, brand.toLowerCase());
    expect(AppConstants.brandSlug, isNotEmpty);
  });

  test('web shell (title + manifest) uses the current brand', () {
    final index = File('web/index.html').readAsStringSync();
    final manifest = File('web/manifest.json').readAsStringSync();
    expect(index, contains('<title>$brand</title>'));
    expect(manifest, contains('"name": "$brand"'));
  });

  test('no user-visible string carries a stale brand name', () {
    // Only strings the user actually reads matter. Comments and imports are
    // harmless, and these internal identifiers MUST keep the historic name —
    // renaming them would break existing installs:
    //   lifeos_store.json  → the data file; a rename orphans every user's data
    //   lifeos.pin.v1      → PIN salt; a change invalidates everyone's PIN
    //   lifeos_default     → Android channel id; a change drops channel settings
    //   data-lifeos-gis / lifeos-video-* → internal DOM ids, never displayed
    const stale = 'lifeos';
    const exemptInternalIds = [
      'lifeos_store.json',
      'lifeos.pin.v1',
      'lifeos_default',
      'data-lifeos-gis',
      'lifeos-video-',
    ];

    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        final lower = line.toLowerCase();
        if (!lower.contains(stale)) continue;
        if (line.startsWith('//') || line.startsWith('///')) continue;
        if (line.startsWith('import ') || line.startsWith('export ')) continue;
        if (exemptInternalIds.any(lower.contains)) continue;
        if (RegExp("['\"][^'\"]*$stale", caseSensitive: false).hasMatch(line)) {
          offenders.add('${entity.path}:${i + 1}: $line');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'Stale brand in user-visible strings:\n${offenders.join('\n')}');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';

/// The placeholder tokens ({name}, {n}, …) used in a string.
Set<String> _tokens(String s) =>
    RegExp(r'\{(\w+)\}').allMatches(s).map((m) => m.group(1)!).toSet();

void main() {
  const table = AppLocalizations.values;
  const langs = AppLocalizations.languages;

  test('every key provides all supported languages, non-empty', () {
    final problems = <String>[];
    table.forEach((key, entry) {
      for (final lang in langs) {
        final v = entry[lang];
        if (v == null) {
          problems.add('$key: missing "$lang"');
        } else if (v.trim().isEmpty) {
          problems.add('$key: empty "$lang"');
        }
      }
    });
    expect(problems, isEmpty, reason: 'Localization gaps:\n${problems.join('\n')}');
  });

  test('a key has no stray extra language codes', () {
    final problems = <String>[];
    table.forEach((key, entry) {
      for (final code in entry.keys) {
        if (!langs.contains(code)) problems.add('$key: unexpected "$code"');
      }
    });
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('placeholder tokens match across all languages', () {
    final problems = <String>[];
    table.forEach((key, entry) {
      final en = _tokens(entry['en'] ?? '');
      for (final lang in langs) {
        final t = _tokens(entry[lang] ?? '');
        if (t.length != en.length || !t.containsAll(en)) {
          problems.add('$key: "$lang" tokens $t != en tokens $en');
        }
      }
    });
    expect(problems, isEmpty, reason: 'Placeholder mismatches:\n${problems.join('\n')}');
  });

  test('the table is non-trivially populated', () {
    expect(table.length, greaterThan(500));
  });
}

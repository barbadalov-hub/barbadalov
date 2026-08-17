import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/health/domain/daily_motivation.dart';

void main() {
  group('parts of the day', () {
    test('split at noon and six', () {
      expect(DailyMotivation.partOf(0), DayPart.morning);
      expect(DailyMotivation.partOf(11), DayPart.morning);
      expect(DailyMotivation.partOf(12), DayPart.day);
      expect(DailyMotivation.partOf(17), DayPart.day);
      expect(DailyMotivation.partOf(18), DayPart.evening);
      expect(DailyMotivation.partOf(23), DayPart.evening);
    });
  });

  group('the walk through the pool', () {
    test('never shows the same line two days running', () {
      for (final part in DayPart.values) {
        var day = DateTime(2026, 1, 1);
        for (var i = 0; i < 400; i++) {
          final next = day.add(const Duration(days: 1));
          expect(
            DailyMotivation.keyFor(day, part),
            isNot(DailyMotivation.keyFor(next, part)),
            reason: 'repeated on ${part.name} at $day — looks like a bug',
          );
          day = next;
        }
      }
    });

    test('uses every line before repeating any of them', () {
      // The point of a strided walk over a random pick: the gap between
      // repeats is exactly the pool size, not a coin flip.
      for (final part in DayPart.values) {
        final seen = <String>{};
        for (var i = 0; i < DailyMotivation.poolSize; i++) {
          seen.add(
              DailyMotivation.keyFor(DateTime(2026, 3, 4 + i), part));
        }
        expect(seen.length, DailyMotivation.poolSize,
            reason: '${part.name} repeats before the pool is used up');
      }
    });

    test('a single day reads as three different thoughts', () {
      final day = DateTime(2026, 6, 15);
      final keys = {
        for (final part in DayPart.values) DailyMotivation.keyFor(day, part),
      };
      expect(keys.length, 3);
    });

    test('the line turns over at midnight, not 24h after it was read', () {
      final lateMonday = DateTime(2026, 2, 2, 23, 40);
      final earlyTuesday = DateTime(2026, 2, 3, 0, 20);
      expect(
        DailyMotivation.keyFor(lateMonday, DayPart.evening),
        isNot(DailyMotivation.keyFor(earlyTuesday, DayPart.evening)),
      );
    });
  });

  test('every line the walk can produce actually exists', () {
    // A missing key would put a raw `motiv.day.7` on screen, which is exactly
    // the sort of thing that only shows up on the one day it happens.
    for (final lang in const ['en', 'ru', 'uk']) {
      final t = AppLocalizations(lang);
      for (final part in DayPart.values) {
        for (var i = 0; i < DailyMotivation.poolSize; i++) {
          final key = 'motiv.${part.name}.$i';
          final line = t.tr(key);
          expect(line, isNot(key), reason: '$key is missing in $lang');
          expect(line.trim(), isNotEmpty, reason: '$key is blank in $lang');
        }
      }
    }
  });

  test('keyAt picks the line for the hour it is handed', () {
    final morning = DateTime(2026, 5, 5, 8);
    final evening = DateTime(2026, 5, 5, 21);
    expect(DailyMotivation.keyAt(morning),
        DailyMotivation.keyFor(morning, DayPart.morning));
    expect(DailyMotivation.keyAt(evening),
        DailyMotivation.keyFor(evening, DayPart.evening));
  });
}

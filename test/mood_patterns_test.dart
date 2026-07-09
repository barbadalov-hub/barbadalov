import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/insights/domain/mood_patterns.dart';
import 'package:lifeos/features/mind/domain/mood.dart';

MoodEntry entry(String date, int mood) =>
    MoodEntry(date: DateTime.parse(date), mood: mood);

void main() {
  group('bestMoodWeekday', () {
    test('returns the weekday with the highest average mood', () {
      // 2024-01-01 is a Monday; 2024-01-06 is a Saturday.
      final entries = [
        entry('2024-01-01', 2), // Mon
        entry('2024-01-08', 2), // Mon
        entry('2024-01-06', 5), // Sat
        entry('2024-01-13', 5), // Sat
        entry('2024-01-02', 3), // Tue (reaches min total)
      ];
      final best = bestMoodWeekday(entries);
      expect(best, isNotNull);
      expect(best!.weekday, DateTime.saturday);
      expect(best.avg, closeTo(5, 1e-9));
      expect(best.days, 2);
    });

    test('needs enough data', () {
      expect(bestMoodWeekday([entry('2024-01-01', 5)]), isNull);
    });
  });

  group('moodTrend', () {
    final now = DateTime(2024, 1, 20);

    test('detects a rising mood', () {
      final entries = [
        entry('2024-01-15', 5),
        entry('2024-01-16', 5),
        entry('2024-01-17', 5),
        entry('2024-01-08', 2),
        entry('2024-01-09', 2),
        entry('2024-01-10', 2),
      ];
      expect(moodTrend(entries, now), MoodTrend.rising);
    });

    test('detects a falling mood', () {
      final entries = [
        entry('2024-01-15', 2),
        entry('2024-01-16', 2),
        entry('2024-01-17', 2),
        entry('2024-01-08', 5),
        entry('2024-01-09', 5),
        entry('2024-01-10', 5),
      ];
      expect(moodTrend(entries, now), MoodTrend.falling);
    });

    test('reports steady for a small change', () {
      final entries = [
        entry('2024-01-15', 3),
        entry('2024-01-16', 3),
        entry('2024-01-17', 3),
        entry('2024-01-08', 3),
        entry('2024-01-09', 3),
        entry('2024-01-10', 3),
      ];
      expect(moodTrend(entries, now), MoodTrend.steady);
    });

    test('is null without enough data in each window', () {
      final entries = [
        entry('2024-01-15', 5),
        entry('2024-01-16', 5),
        entry('2024-01-17', 5),
        entry('2024-01-08', 2), // only one in the previous window
      ];
      expect(moodTrend(entries, now), isNull);
    });
  });
}

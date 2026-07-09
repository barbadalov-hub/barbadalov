import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/insights/domain/logging_streak.dart';

void main() {
  final now = DateTime(2024, 3, 10, 15, 0); // mid-afternoon
  Set<int> days(List<String> ds) =>
      {for (final d in ds) dayKeyOf(DateTime.parse(d))};

  test('counts consecutive days ending today', () {
    expect(
      loggingStreak(days(['2024-03-08', '2024-03-09', '2024-03-10']), now),
      3,
    );
  });

  test('a gap breaks the streak', () {
    // 03-07 logged, 03-08 missing, then 09 & 10 → streak is 2 (09,10).
    expect(
      loggingStreak(days(['2024-03-07', '2024-03-09', '2024-03-10']), now),
      2,
    );
  });

  test('today not logged yet is fine if yesterday was', () {
    expect(loggingStreak(days(['2024-03-08', '2024-03-09']), now), 2);
  });

  test('lapsed (nothing today or yesterday) is zero', () {
    expect(loggingStreak(days(['2024-03-06', '2024-03-07']), now), 0);
  });

  test('empty is zero', () {
    expect(loggingStreak({}, now), 0);
  });

  test('a single today entry is a streak of one', () {
    expect(loggingStreak(days(['2024-03-10']), now), 1);
  });
}

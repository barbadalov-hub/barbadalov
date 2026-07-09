import 'package:lifeos/features/mind/domain/mood.dart';

/// The direction mood is heading over the last two weeks.
enum MoodTrend { rising, steady, falling }

/// The weekday a person tends to feel best, with its average mood.
class WeekdayMood {
  final int weekday; // DateTime.monday..sunday (1..7)
  final double avg;
  final int days;
  const WeekdayMood(this.weekday, this.avg, this.days);
}

/// The weekday with the highest average mood. Needs a little data to be
/// meaningful: at least [minTotal] entries overall and [minPerDay] on the
/// winning day. Returns null otherwise. Pure.
WeekdayMood? bestMoodWeekday(
  List<MoodEntry> entries, {
  int minTotal = 5,
  int minPerDay = 2,
}) {
  if (entries.length < minTotal) return null;
  final sum = <int, double>{};
  final count = <int, int>{};
  for (final e in entries) {
    final w = e.date.weekday;
    sum[w] = (sum[w] ?? 0) + e.mood;
    count[w] = (count[w] ?? 0) + 1;
  }
  WeekdayMood? best;
  for (final w in count.keys) {
    if (count[w]! < minPerDay) continue;
    final avg = sum[w]! / count[w]!;
    if (best == null || avg > best.avg) {
      best = WeekdayMood(w, avg, count[w]!);
    }
  }
  return best;
}

/// Compares the last 7 days of mood to the 7 before. Returns null until both
/// windows have at least [minPerWindow] entries. A change under [threshold] is
/// reported as steady. Pure.
MoodTrend? moodTrend(
  List<MoodEntry> entries,
  DateTime now, {
  int minPerWindow = 3,
  double threshold = 0.3,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final recentStart = today.subtract(const Duration(days: 6));
  final prevStart = today.subtract(const Duration(days: 13));

  double sumRecent = 0, sumPrev = 0;
  int nRecent = 0, nPrev = 0;
  for (final e in entries) {
    final d = DateTime(e.date.year, e.date.month, e.date.day);
    if (!d.isBefore(recentStart) && !d.isAfter(today)) {
      sumRecent += e.mood;
      nRecent++;
    } else if (!d.isBefore(prevStart) && d.isBefore(recentStart)) {
      sumPrev += e.mood;
      nPrev++;
    }
  }
  if (nRecent < minPerWindow || nPrev < minPerWindow) return null;
  final delta = sumRecent / nRecent - sumPrev / nPrev;
  if (delta.abs() < threshold) return MoodTrend.steady;
  return delta > 0 ? MoodTrend.rising : MoodTrend.falling;
}

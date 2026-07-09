/// Day key = year*10000 + month*100 + day, so days compare/sort as ints.
int dayKeyOf(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

/// The number of consecutive days (ending today, or yesterday if nothing is
/// logged yet today) that appear in [loggedDays]. Returns 0 if the streak has
/// already lapsed. Pure — the app's "you've shown up N days in a row" metric.
int loggingStreak(Set<int> loggedDays, DateTime now) {
  if (loggedDays.isEmpty) return 0;
  var cursor = DateTime(now.year, now.month, now.day);

  // Today not logged yet is fine — the streak can still be alive from yesterday.
  if (!loggedDays.contains(dayKeyOf(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!loggedDays.contains(dayKeyOf(cursor))) return 0;
  }

  var count = 0;
  while (loggedDays.contains(dayKeyOf(cursor))) {
    count++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return count;
}

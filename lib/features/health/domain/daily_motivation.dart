/// Which third of the day a line is written for. Morning wants to set an
/// intention, midday wants to interrupt a slump, evening wants to close the
/// day kindly — the same sentence cannot do all three.
enum DayPart { morning, day, evening }

/// Picks the day's line, without storing anything.
///
/// The line has to feel chosen rather than random: two identical days in a row
/// makes the app look broken, and a random pick collides surprisingly often
/// (with a pool of 12 there is a ~1-in-12 chance of repeating tomorrow). So the
/// pool is walked in a fixed stride instead. A stride coprime with the pool
/// size visits every line exactly once before any repeat, which makes the
/// guarantee exact: no line comes back for a full [poolSize] days.
class DailyMotivation {
  /// Lines available per part of day. The i18n table holds
  /// `motiv.<part>.<0..poolSize-1>` for each.
  static const poolSize = 12;

  /// Coprime with [poolSize], so the walk is a full cycle rather than an orbit
  /// through a handful of lines. 5 also moves far enough each day that
  /// consecutive lines do not feel like neighbours from one list.
  static const _stride = 5;

  static DayPart partOf(int hour) {
    if (hour < 12) return DayPart.morning;
    if (hour < 18) return DayPart.day;
    return DayPart.evening;
  }

  /// Days elapsed, counted on calendar dates so a line changes at midnight
  /// rather than 24 hours after the last one was shown.
  static int _dayOrdinal(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day)
          .difference(DateTime.utc(2020))
          .inDays;

  /// The i18n key of today's line for [part].
  static String keyFor(DateTime date, DayPart part) {
    // Offsetting by part keeps morning, day and evening on different rungs of
    // the same walk, so one day never reads as three variations of one thought.
    final index =
        ((_dayOrdinal(date) * _stride) + part.index * 4) % poolSize;
    return 'motiv.${part.name}.$index';
  }

  /// The line for the moment [now] falls in.
  static String keyAt(DateTime now) => keyFor(now, partOf(now.hour));
}

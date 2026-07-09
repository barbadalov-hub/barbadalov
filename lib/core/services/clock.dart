/// Abstraction over "now" so time-dependent logic (budget-per-remaining-day,
/// streaks, reminders) is deterministic under test.
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

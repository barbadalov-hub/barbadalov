import 'package:lifeos/features/reminders/domain/entities/reminder.dart';

/// The data signals the suggester grades reminders against.
class ReminderSuggestionInputs {
  final double avgSleep; // hours, 0 if none logged
  final double avgWater; // glasses/day
  final bool moodLoggedRecently; // any mood entry in the last few days
  final bool overBudget;

  const ReminderSuggestionInputs({
    this.avgSleep = 0,
    this.avgWater = 0,
    this.moodLoggedRecently = true,
    this.overBudget = false,
  });
}

/// Suggests helpful daily reminders from the user's data, skipping kinds they
/// already have. Ordered by urgency. Pure — unit-tested.
List<ReminderKind> suggestReminderKinds(
  ReminderSuggestionInputs i,
  Set<ReminderKind> existing,
) {
  final out = <ReminderKind>[];
  void consider(ReminderKind kind, bool condition) {
    if (condition && !existing.contains(kind)) out.add(kind);
  }

  consider(ReminderKind.sleep, i.avgSleep > 0 && i.avgSleep < 7);
  consider(ReminderKind.budget, i.overBudget);
  consider(ReminderKind.water, i.avgWater < 6);
  consider(ReminderKind.checkin, !i.moodLoggedRecently);
  return out;
}

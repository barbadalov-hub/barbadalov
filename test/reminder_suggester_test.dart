import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/reminders/domain/entities/reminder.dart';
import 'package:lifeos/features/reminders/domain/reminder_suggester.dart';

void main() {
  group('suggestReminderKinds', () {
    test('suggests sleep when sleeping under 7h', () {
      final s = suggestReminderKinds(
        const ReminderSuggestionInputs(avgSleep: 5.5, avgWater: 8, moodLoggedRecently: true),
        {},
      );
      expect(s, contains(ReminderKind.sleep));
      expect(s, isNot(contains(ReminderKind.water)));
    });

    test('suggests water when hydration is low', () {
      final s = suggestReminderKinds(
        const ReminderSuggestionInputs(avgSleep: 8, avgWater: 3, moodLoggedRecently: true),
        {},
      );
      expect(s, contains(ReminderKind.water));
    });

    test('suggests a check-in when mood is stale, budget when overspent', () {
      final s = suggestReminderKinds(
        const ReminderSuggestionInputs(
            avgSleep: 8, avgWater: 8, moodLoggedRecently: false, overBudget: true),
        {},
      );
      expect(s, containsAll([ReminderKind.budget, ReminderKind.checkin]));
    });

    test('never suggests a kind the user already has', () {
      final s = suggestReminderKinds(
        const ReminderSuggestionInputs(avgSleep: 5, avgWater: 3),
        {ReminderKind.sleep, ReminderKind.water},
      );
      expect(s, isNot(contains(ReminderKind.sleep)));
      expect(s, isNot(contains(ReminderKind.water)));
    });

    test('healthy signals suggest nothing', () {
      final s = suggestReminderKinds(
        const ReminderSuggestionInputs(
            avgSleep: 8, avgWater: 8, moodLoggedRecently: true, overBudget: false),
        {},
      );
      expect(s, isEmpty);
    });

    test('sleep needs real data (0 hours means not logged)', () {
      final s = suggestReminderKinds(
        const ReminderSuggestionInputs(avgSleep: 0, avgWater: 8, moodLoggedRecently: true),
        {},
      );
      expect(s, isNot(contains(ReminderKind.sleep)));
    });
  });
}

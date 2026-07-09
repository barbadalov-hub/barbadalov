import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/mind/domain/entities/habit.dart';

void main() {
  final now = DateTime(2026, 7, 5); // Sunday
  DateTime daysAgo(int n) => now.subtract(Duration(days: n));

  test('toggling on/off builds history and derives the streak', () {
    var h = const Habit(id: 'a', name: 'Read', emoji: '📚');

    h = h.toggledOn(now); // today
    expect(h.doneToday, isTrue);
    expect(h.streak, 1);
    expect(h.completedDates, hasLength(1));

    h = h.toggledOn(daysAgo(1)).refreshedFor(now); // + yesterday
    expect(h.streak, 2);

    h = h.toggledOn(now).refreshedFor(now); // untoggle today
    expect(h.doneToday, isFalse);
    expect(h.streak, 1); // yesterday still counts
  });

  test('a gap breaks the streak', () {
    var h = const Habit(id: 'a', name: 'A', emoji: 'x');
    for (final n in [0, 1, 3, 4]) {
      h = h.toggledOn(daysAgo(n));
    }
    h = h.refreshedFor(now);
    // today + yesterday consecutive; day-2 missing → streak = 2.
    expect(h.streak, 2);
  });

  test('completionsThisWeek counts Mon–today only', () {
    var h = const Habit(id: 'a', name: 'A', emoji: 'x', targetPerWeek: 3);
    expect(h.isFlexible, isTrue);
    for (final n in [0, 1, 8]) {
      // today, yesterday (this week) + 8 days ago (last week)
      h = h.toggledOn(daysAgo(n));
    }
    expect(h.completionsThisWeek(now), 2);
  });

  test('JSON round-trips completedDates and target', () {
    final h = const Habit(id: 'a', name: 'A', emoji: 'x', targetPerWeek: 4)
        .toggledOn(DateTime(2026, 7, 1))
        .toggledOn(DateTime(2026, 7, 2));
    final back = Habit.fromJson(h.toJson());
    expect(back.targetPerWeek, 4);
    expect(back.completedDates.length, 2);
    expect(back.doneOn(DateTime(2026, 7, 1)), isTrue);
  });
}

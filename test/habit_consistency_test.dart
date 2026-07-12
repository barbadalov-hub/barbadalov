import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/mind/domain/entities/habit.dart';
import 'package:lifeos/features/mind/domain/habit_consistency.dart';

/// A Wednesday, so "this week" (Mon–Sun) is well-defined and has past days.
final _now = DateTime(2026, 1, 14); // 2026-01-14 is a Wednesday
DateTime _thisWeek(int weekday) {
  // Monday of _now's week + (weekday-1) days.
  final monday = _now.subtract(Duration(days: _now.weekday - 1));
  return DateTime(monday.year, monday.month, monday.day + (weekday - 1));
}

Habit _habit({required int target, required List<int> doneWeekdays}) => Habit(
      id: 't',
      name: 'h',
      emoji: '',
      targetPerWeek: target,
      completedDates: [for (final wd in doneWeekdays) _thisWeek(wd)],
    );

void main() {
  group('HabitConsistency.weekly', () {
    test('sums completions and targets across habits', () {
      final habits = [
        _habit(target: 7, doneWeekdays: [1, 2, 3]), // 3 of 7
        _habit(target: 3, doneWeekdays: [1, 2]), // 2 of 3
      ];
      final w = HabitConsistency.weekly(habits, _now);
      expect(w.completed, 5);
      expect(w.target, 10);
      expect(w.pct, 50);
    });

    test('caps each habit at its own target', () {
      // A 2×/week habit done 4 times counts as 2, not 4.
      final habits = [_habit(target: 2, doneWeekdays: [1, 2, 3, 4])];
      final w = HabitConsistency.weekly(habits, _now);
      expect(w.completed, 2);
      expect(w.target, 2);
      expect(w.pct, 100);
    });

    test('ignores completions from other weeks', () {
      final lastWeek = _now.subtract(const Duration(days: 7));
      final h = Habit(
        id: 't',
        name: 'h',
        emoji: '',
        targetPerWeek: 7,
        completedDates: [lastWeek, _thisWeek(1)],
      );
      final w = HabitConsistency.weekly([h], _now);
      expect(w.completed, 1);
    });

    test('no habits is a clean zero, not a divide-by-zero', () {
      final w = HabitConsistency.weekly(const [], _now);
      expect(w.completed, 0);
      expect(w.target, 0);
      expect(w.pct, 0);
    });
  });
}

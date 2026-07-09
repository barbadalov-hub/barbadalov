import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/mind/domain/achievements.dart';
import 'package:lifeos/features/mind/domain/entities/habit.dart';

void main() {
  const engine = AchievementEngine();

  test('best streak is the max across habits', () {
    final habits = [
      const Habit(id: 'a', name: 'A', emoji: '📚', streak: 8),
      const Habit(id: 'b', name: 'B', emoji: '🏋️', streak: 2),
    ];
    expect(engine.bestStreak(habits), 8);
  });

  test('earned badges reflect streak tiers and consistency', () {
    final habits = [
      const Habit(id: 'a', name: 'A', emoji: '📚', streak: 8, doneToday: true),
      const Habit(id: 'b', name: 'B', emoji: '🏋️', streak: 2, doneToday: true),
    ];
    final badges = engine.evaluate(habits);
    final earned = {for (final b in badges) b.id: b.earned};

    expect(earned['streak3'], isTrue); // best 8 >= 3
    expect(earned['streak7'], isTrue); // best 8 >= 7
    expect(earned['streak14'], isFalse); // best 8 < 14
    expect(earned['allDone'], isTrue); // 2 of 2 done
    expect(earned['collector'], isFalse); // only 2 habits
    expect(engine.earnedCount(habits), 3);
  });

  test('empty habits earn nothing and best streak is zero', () {
    expect(engine.bestStreak(const []), 0);
    expect(engine.earnedCount(const []), 0);
  });
}

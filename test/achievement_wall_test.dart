import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/achievements/domain/achievement.dart';

void main() {
  const engine = AchievementEngine();

  AchievementStatus byId(AchievementInputs i, String id) =>
      engine.evaluate(i).firstWhere((s) => s.def.id == id);

  test('fresh install unlocks nothing', () {
    const i = AchievementInputs();
    expect(engine.unlockedCount(i), 0);
    expect(engine.total, 18);
    expect(engine.evaluate(i).length, 18);
  });

  test('logging-streak badges grade against the daily streak', () {
    const i = AchievementInputs(loggingStreak: 12);
    expect(byId(i, 'log_7').unlocked, isTrue);
    expect(byId(i, 'log_30').unlocked, isFalse);
    expect(byId(i, 'log_30').ratio, closeTo(0.4, 1e-9));
  });

  test('a 30-day streak unlocks the 7 and 30 tiers but not 100', () {
    const i = AchievementInputs(bestStreak: 30);
    expect(byId(i, 'streak_7').unlocked, isTrue);
    expect(byId(i, 'streak_30').unlocked, isTrue);
    expect(byId(i, 'streak_100').unlocked, isFalse);
  });

  test('progress ratio is fractional and clamped', () {
    const i = AchievementInputs(trackedDays: 15, peakSteps: 20000);
    expect(byId(i, 'tracked_30').ratio, closeTo(0.5, 1e-9));
    // 20k steps exceeds the 10k goal → ratio clamps to 1 and unlocks.
    expect(byId(i, 'steps_10k').ratio, 1.0);
    expect(byId(i, 'steps_10k').unlocked, isTrue);
  });

  test('money and mastery badges grade correctly', () {
    const i = AchievementInputs(
      habitsCount: 5,
      goalsCompleted: 1,
      goalsSavedMajor: 1500,
      pillarsActive: 5,
      transactions: 12,
    );
    expect(byId(i, 'habit_collector').unlocked, isTrue);
    expect(byId(i, 'goal_first').unlocked, isTrue);
    expect(byId(i, 'saver').unlocked, isTrue);
    expect(byId(i, 'harmony').unlocked, isTrue);
    expect(byId(i, 'money_log').unlocked, isTrue);
    expect(engine.unlockedCount(i), greaterThanOrEqualTo(5));
  });

  test('newlyUnlocked returns only badges not already known', () {
    const i = AchievementInputs(habitsCount: 1, bestStreak: 7);
    final statuses = engine.evaluate(i);
    // habit_first + streak_7 are unlocked; treat habit_first as already known.
    final fresh = newlyUnlocked({'habit_first'}, statuses);
    final ids = fresh.map((s) => s.def.id).toSet();
    expect(ids, contains('streak_7'));
    expect(ids, isNot(contains('habit_first')));
    expect(fresh.every((s) => s.unlocked), isTrue);
  });

  test('closestLocked picks the locked badge with the highest progress', () {
    // streak 20/30 (0.67) is closer than streak 20/100 (0.20); nothing unlocked
    // above it in ratio among locked ones.
    const i = AchievementInputs(bestStreak: 20);
    final next = closestLocked(engine.evaluate(i));
    expect(next, isNotNull);
    expect(next!.def.id, 'streak_30');
    expect(next.unlocked, isFalse);
  });

  test('closestLocked is null when everything is unlocked', () {
    const maxed = AchievementInputs(
      habitsCount: 10,
      bestStreak: 200,
      loggingStreak: 200,
      peakSteps: 99999,
      trackedDays: 60,
      lifeScore: 100,
      transactions: 99,
      goalsCompleted: 9,
      goalsSavedMajor: 99999,
      moodEntries: 99,
      booksFinished: 9,
      pillarsActive: 5,
    );
    expect(closestLocked(engine.evaluate(maxed)), isNull);
  });
}

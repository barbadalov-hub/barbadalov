import 'package:lifeos/features/mind/domain/entities/habit.dart';

/// A gamification badge earned from habit behaviour. Progress/goal drive both
/// the "earned" state and a progress bar toward the next tier.
class HabitBadge {
  final String id;
  final String emoji;
  final String titleKey;
  final int progress;
  final int goal;

  const HabitBadge({
    required this.id,
    required this.emoji,
    required this.titleKey,
    required this.progress,
    required this.goal,
  });

  bool get earned => progress >= goal;
  double get ratio => goal == 0 ? 1 : (progress / goal).clamp(0.0, 1.0);
}

/// Derives badges from the current habit list. Pure — the streaks themselves
/// live on [Habit]; this just turns them into milestones and consistency wins.
class AchievementEngine {
  const AchievementEngine();

  /// Streak milestones, in ascending order.
  static const streakTiers = <(int, String, String)>[
    (3, '🔥', 'ach.streak3'),
    (7, '⚡', 'ach.streak7'),
    (14, '💪', 'ach.streak14'),
    (30, '🏆', 'ach.streak30'),
    (100, '👑', 'ach.streak100'),
  ];

  int bestStreak(List<Habit> habits) =>
      habits.isEmpty ? 0 : habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);

  List<HabitBadge> evaluate(List<Habit> habits) {
    final best = bestStreak(habits);
    final doneToday = habits.where((h) => h.doneToday).length;

    return [
      for (final (goal, emoji, key) in streakTiers)
        HabitBadge(
          id: 'streak$goal',
          emoji: emoji,
          titleKey: key,
          progress: best,
          goal: goal,
        ),
      HabitBadge(
        id: 'allDone',
        emoji: '✅',
        titleKey: 'ach.allDone',
        progress: doneToday,
        goal: habits.isEmpty ? 1 : habits.length,
      ),
      HabitBadge(
        id: 'collector',
        emoji: '🌟',
        titleKey: 'ach.collector',
        progress: habits.length,
        goal: 5,
      ),
    ];
  }

  int earnedCount(List<Habit> habits) =>
      evaluate(habits).where((b) => b.earned).length;
}

/// The pillar a badge belongs to (for grouping on the trophy wall).
enum AchievementCategory { habits, health, money, mind, meta }

/// Aggregated numbers the achievement engine grades against. All default to 0 so
/// a fresh install simply shows everything locked.
class AchievementInputs {
  final int bestStreak;
  final int loggingStreak; // consecutive days anything was logged
  final int habitsCount;
  final int goalsCompleted;
  final double goalsSavedMajor;
  final int peakSteps;
  final int moodEntries;
  final int booksFinished;
  final int transactions;
  final int trackedDays;
  final int lifeScore;
  final int pillarsActive; // how many pillars have any data (0..5)

  const AchievementInputs({
    this.bestStreak = 0,
    this.loggingStreak = 0,
    this.habitsCount = 0,
    this.goalsCompleted = 0,
    this.goalsSavedMajor = 0,
    this.peakSteps = 0,
    this.moodEntries = 0,
    this.booksFinished = 0,
    this.transactions = 0,
    this.trackedDays = 0,
    this.lifeScore = 0,
    this.pillarsActive = 0,
  });
}

/// A single badge definition: what it takes to earn it and how to read current
/// progress out of [AchievementInputs].
class AchievementDef {
  final String id;
  final AchievementCategory category;
  final String emoji;
  final String titleKey;
  final String descKey;
  final num goal;
  final num Function(AchievementInputs) progress;

  const AchievementDef({
    required this.id,
    required this.category,
    required this.emoji,
    required this.titleKey,
    required this.descKey,
    required this.goal,
    required this.progress,
  });
}

/// A graded badge for the current user state.
class AchievementStatus {
  final AchievementDef def;
  final num current;

  const AchievementStatus(this.def, this.current);

  bool get unlocked => current >= def.goal;
  double get ratio =>
      def.goal <= 0 ? 1 : (current / def.goal).clamp(0.0, 1.0).toDouble();
}

/// Grades the fixed badge catalog against the user's aggregated stats. Pure.
class AchievementEngine {
  const AchievementEngine();

  List<AchievementDef> get catalog => [
        // Habits.
        AchievementDef(
          id: 'habit_first',
          category: AchievementCategory.habits,
          emoji: '🌱',
          titleKey: 'ach.habitFirst.t',
          descKey: 'ach.habitFirst.d',
          goal: 1,
          progress: (i) => i.habitsCount,
        ),
        AchievementDef(
          id: 'habit_collector',
          category: AchievementCategory.habits,
          emoji: '🧩',
          titleKey: 'ach.habitCollector.t',
          descKey: 'ach.habitCollector.d',
          goal: 5,
          progress: (i) => i.habitsCount,
        ),
        AchievementDef(
          id: 'streak_7',
          category: AchievementCategory.habits,
          emoji: '🔥',
          titleKey: 'ach.streak7.t',
          descKey: 'ach.streak7.d',
          goal: 7,
          progress: (i) => i.bestStreak,
        ),
        AchievementDef(
          id: 'streak_30',
          category: AchievementCategory.habits,
          emoji: '🏆',
          titleKey: 'ach.streak30.t',
          descKey: 'ach.streak30.d',
          goal: 30,
          progress: (i) => i.bestStreak,
        ),
        AchievementDef(
          id: 'streak_100',
          category: AchievementCategory.habits,
          emoji: '💎',
          titleKey: 'ach.streak100.t',
          descKey: 'ach.streak100.d',
          goal: 100,
          progress: (i) => i.bestStreak,
        ),
        // Health.
        AchievementDef(
          id: 'steps_10k',
          category: AchievementCategory.health,
          emoji: '👟',
          titleKey: 'ach.steps10k.t',
          descKey: 'ach.steps10k.d',
          goal: 10000,
          progress: (i) => i.peakSteps,
        ),
        AchievementDef(
          id: 'tracked_30',
          category: AchievementCategory.health,
          emoji: '🗓️',
          titleKey: 'ach.tracked30.t',
          descKey: 'ach.tracked30.d',
          goal: 30,
          progress: (i) => i.trackedDays,
        ),
        AchievementDef(
          id: 'score_80',
          category: AchievementCategory.health,
          emoji: '⭐',
          titleKey: 'ach.score80.t',
          descKey: 'ach.score80.d',
          goal: 80,
          progress: (i) => i.lifeScore,
        ),
        // Money.
        AchievementDef(
          id: 'money_log',
          category: AchievementCategory.money,
          emoji: '🧾',
          titleKey: 'ach.moneyLog.t',
          descKey: 'ach.moneyLog.d',
          goal: 10,
          progress: (i) => i.transactions,
        ),
        AchievementDef(
          id: 'goal_first',
          category: AchievementCategory.money,
          emoji: '🎯',
          titleKey: 'ach.goalFirst.t',
          descKey: 'ach.goalFirst.d',
          goal: 1,
          progress: (i) => i.goalsCompleted,
        ),
        AchievementDef(
          id: 'saver',
          category: AchievementCategory.money,
          emoji: '💰',
          titleKey: 'ach.saver.t',
          descKey: 'ach.saver.d',
          goal: 1000,
          progress: (i) => i.goalsSavedMajor,
        ),
        // Mind.
        AchievementDef(
          id: 'mood_7',
          category: AchievementCategory.mind,
          emoji: '📔',
          titleKey: 'ach.mood7.t',
          descKey: 'ach.mood7.d',
          goal: 7,
          progress: (i) => i.moodEntries,
        ),
        AchievementDef(
          id: 'mood_30',
          category: AchievementCategory.mind,
          emoji: '🧠',
          titleKey: 'ach.mood30.t',
          descKey: 'ach.mood30.d',
          goal: 30,
          progress: (i) => i.moodEntries,
        ),
        AchievementDef(
          id: 'book_1',
          category: AchievementCategory.mind,
          emoji: '📚',
          titleKey: 'ach.book1.t',
          descKey: 'ach.book1.d',
          goal: 1,
          progress: (i) => i.booksFinished,
        ),
        AchievementDef(
          id: 'book_5',
          category: AchievementCategory.mind,
          emoji: '🦉',
          titleKey: 'ach.book5.t',
          descKey: 'ach.book5.d',
          goal: 5,
          progress: (i) => i.booksFinished,
        ),
        // Meta.
        AchievementDef(
          id: 'log_7',
          category: AchievementCategory.meta,
          emoji: '⚡',
          titleKey: 'ach.log7.t',
          descKey: 'ach.log7.d',
          goal: 7,
          progress: (i) => i.loggingStreak,
        ),
        AchievementDef(
          id: 'log_30',
          category: AchievementCategory.meta,
          emoji: '🌠',
          titleKey: 'ach.log30.t',
          descKey: 'ach.log30.d',
          goal: 30,
          progress: (i) => i.loggingStreak,
        ),
        AchievementDef(
          id: 'harmony',
          category: AchievementCategory.meta,
          emoji: '🌌',
          titleKey: 'ach.harmony.t',
          descKey: 'ach.harmony.d',
          goal: 5,
          progress: (i) => i.pillarsActive,
        ),
      ];

  List<AchievementStatus> evaluate(AchievementInputs i) =>
      [for (final d in catalog) AchievementStatus(d, d.progress(i))];

  int unlockedCount(AchievementInputs i) =>
      evaluate(i).where((s) => s.unlocked).length;

  int get total => catalog.length;
}

/// Unlocked badges whose id isn't in [known] — i.e. earned since last checked.
List<AchievementStatus> newlyUnlocked(
  Set<String> known,
  List<AchievementStatus> current,
) =>
    [for (final s in current) if (s.unlocked && !known.contains(s.def.id)) s];

/// The still-locked badge closest to unlocking (highest progress ratio), or null
/// when everything is unlocked. Powers the "almost there" teaser.
AchievementStatus? closestLocked(List<AchievementStatus> statuses) {
  AchievementStatus? best;
  for (final s in statuses) {
    if (s.unlocked) continue;
    if (best == null || s.ratio > best.ratio) best = s;
  }
  return best;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/i18n/locale_controller.dart';
import 'package:lifeos/features/achievements/domain/achievement.dart';
import 'package:lifeos/features/goals/presentation/providers/goal_providers.dart';
import 'package:lifeos/features/home/presentation/providers/today_providers.dart';
import 'package:lifeos/features/insights/presentation/providers/insights_providers.dart';
import 'package:lifeos/features/mind/presentation/providers/mind_providers.dart';
import 'package:lifeos/features/mind/presentation/providers/mood_providers.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/features/notifications/domain/entities/app_notification.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_prefs.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Aggregates the numbers that grade every badge from across the app.
final achievementInputsProvider = Provider<AchievementInputs>((ref) {
  final habits = ref.watch(habitsProvider).valueOrNull ?? const [];
  final goals = ref.watch(goalsProvider).valueOrNull ?? const [];
  final books = ref.watch(booksProvider).valueOrNull ?? const [];
  final txs = ref.watch(transactionsProvider).valueOrNull ?? const [];
  final moods = ref.watch(moodLogProvider);
  final insights = ref.watch(insightsProvider);
  final score = ref.watch(lifeScoreProvider).total;

  var savedMajor = 0.0;
  var completed = 0;
  for (final g in goals) {
    savedMajor += g.saved.major;
    if (g.isComplete) completed++;
  }
  final peakSteps = insights.peakStepsDay?.steps ?? 0;

  final pillars = [
    txs.isNotEmpty,
    habits.isNotEmpty,
    moods.isNotEmpty,
    peakSteps > 0 || insights.trackedDays > 0,
    goals.isNotEmpty,
  ].where((b) => b).length;

  return AchievementInputs(
    bestStreak: insights.bestStreak,
    loggingStreak: insights.loggingStreak,
    habitsCount: habits.length,
    goalsCompleted: completed,
    goalsSavedMajor: savedMajor,
    peakSteps: peakSteps,
    moodEntries: moods.length,
    booksFinished: books.where((b) => b.isFinished).length,
    transactions: txs.length,
    trackedDays: insights.trackedDays,
    lifeScore: score,
    pillarsActive: pillars,
  );
});

/// Every badge graded against the current state.
final achievementsProvider = Provider<List<AchievementStatus>>((ref) {
  return const AchievementEngine()
      .evaluate(ref.watch(achievementInputsProvider));
});

/// How many badges are unlocked (for the More-tile subtitle / header count).
final achievementsUnlockedProvider = Provider<int>((ref) {
  return ref.watch(achievementsProvider).where((s) => s.unlocked).length;
});

/// The still-locked badge closest to unlocking — for the Today "almost there"
/// teaser.
final nextAchievementProvider = Provider<AchievementStatus?>((ref) {
  return closestLocked(ref.watch(achievementsProvider));
});

/// Watches for newly earned badges and fires a celebratory notification for
/// each (→ phone push + in-app feed + badge). Kept alive by [HomeShell]. The
/// first run seeds the "already unlocked" set silently so it never spams badges
/// earned before this feature existed.
final achievementAlertServiceProvider = Provider<void>((ref) {
  final statuses = ref.watch(achievementsProvider);
  Future.microtask(() {
    try {
      _checkUnlocks(ref, statuses);
    } catch (_) {}
  });
});

void _checkUnlocks(Ref ref, List<AchievementStatus> statuses) {
  const key = 'ach.unlocked';
  final store = ref.read(keyValueStoreProvider);
  final currentIds = {for (final s in statuses) if (s.unlocked) s.def.id};

  final raw = store.getString(key);
  if (raw == null) {
    // First ever run: remember what's already earned, announce nothing.
    store.setString(key, currentIds.join(','));
    return;
  }
  final known = raw.isEmpty ? <String>{} : raw.split(',').toSet();
  final fresh = newlyUnlocked(known, statuses);
  if (fresh.isEmpty) return;

  if (ref.read(notificationPrefsProvider).enabled('achievement')) {
    final lang = ref.read(localeProvider)?.languageCode ?? 'en';
    final t = AppLocalizations(lang);
    final now = ref.read(clockProvider).now();
    for (final s in fresh) {
      ref.read(notificationRepositoryProvider).add(AppNotification(
            id: 'ach:${s.def.id}',
            tier: NotificationTier.aiInsight,
            titleKey: 'ach.unlockedPush',
            bodyKey: 'ach.unlockedBody',
            params: {'name': '${s.def.emoji} ${t.tr(s.def.titleKey)}'},
            createdAt: now,
          ));
    }
  }
  store.setString(key, {...known, ...currentIds}.join(','));
}

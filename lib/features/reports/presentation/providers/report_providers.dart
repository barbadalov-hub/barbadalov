import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/i18n/locale_controller.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/features/mind/presentation/providers/mind_providers.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/features/notifications/domain/entities/app_notification.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_prefs.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// A one-glance summary of the last 7 days across every pillar.
class WeeklyReport {
  final Money spent;
  final Money income;
  final List<(Category, Money)> topCategories;
  final int avgSteps;
  final double avgWater;
  final double avgSleep;
  final int habitsDone;
  final int habitsTotal;
  final int bestStreak;
  final double? weightDelta;

  const WeeklyReport({
    required this.spent,
    required this.income,
    required this.topCategories,
    required this.avgSteps,
    required this.avgWater,
    required this.avgSleep,
    required this.habitsDone,
    required this.habitsTotal,
    required this.bestStreak,
    required this.weightDelta,
  });

  Money get net => income - spent;
}

final weeklyReportProvider = Provider<WeeklyReport>((ref) {
  final now = ref.watch(clockProvider).now();
  final since =
      DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
  bool inWindow(DateTime d) =>
      !DateTime(d.year, d.month, d.day).isBefore(since);

  // Money.
  final txs = ref.watch(transactionsProvider).valueOrNull ?? const [];
  var spent = 0;
  var income = 0;
  final byCat = <String, int>{};
  for (final t in txs) {
    if (!inWindow(t.date)) continue;
    if (t.isExpense) {
      spent += t.amount.minorUnits;
      byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount.minorUnits;
    } else {
      income += t.amount.minorUnits;
    }
  }
  final topCats = byCat.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  // Health (past archived days + today).
  final days = [...ref.watch(healthHistoryProvider)];
  final today = ref.watch(todayHealthProvider).valueOrNull;
  if (today != null) days.add(today);
  final week = days.where((d) => inWindow(d.date)).toList();
  var avgSteps = 0;
  var avgWater = 0.0;
  var avgSleep = 0.0;
  if (week.isNotEmpty) {
    avgSteps =
        (week.map((d) => d.steps).reduce((a, b) => a + b) / week.length).round();
    avgWater =
        week.map((d) => d.waterGlasses).reduce((a, b) => a + b) / week.length;
    avgSleep =
        week.map((d) => d.sleepHours).reduce((a, b) => a + b) / week.length;
  }

  // Mind.
  final habits = ref.watch(habitsProvider).valueOrNull ?? const [];
  final done = habits.where((h) => h.doneToday).length;
  final best = ref.watch(bestStreakProvider);

  // Weight change across the window.
  final weights = ref.watch(weightHistoryProvider).where((p) => inWindow(p.$1)).toList();
  final weightDelta =
      weights.length >= 2 ? weights.last.$2 - weights.first.$2 : null;

  return WeeklyReport(
    spent: Money(spent),
    income: Money(income),
    topCategories: [
      for (final e in topCats.take(3)) (DefaultCategories.byId(e.key), Money(e.value)),
    ],
    avgSteps: avgSteps,
    avgWater: avgWater,
    avgSleep: avgSleep,
    habitsDone: done,
    habitsTotal: habits.length,
    bestStreak: best,
    weightDelta: weightDelta,
  );
});

/// Fires one weekend "here's your week" notification per week (deduped). Kept
/// alive by [HomeShell]. Adding it also pushes to the phone and bumps the badge.
final weeklyReportServiceProvider = Provider<void>((ref) {
  Future.microtask(() {
    try {
      _maybePush(ref);
    } catch (_) {}
  });
});

void _maybePush(Ref ref) {
  if (!ref.read(notificationPrefsProvider).enabled('weekly')) return;
  final now = ref.read(clockProvider).now();
  if (now.weekday < DateTime.saturday) return; // weekend recap only
  final monday = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  final key = 'weekly:${monday.year}-${monday.month}-${monday.day}';
  final store = ref.read(keyValueStoreProvider);
  if (store.getString('reports.weeklyPushed') == key) return;

  final report = ref.read(weeklyReportProvider);
  final lang = ref.read(localeProvider)?.languageCode ?? 'en';
  final t = AppLocalizations(lang);
  final topCat = report.topCategories.isEmpty
      ? t.tr('report.none')
      : t.tr('cat.${report.topCategories.first.$1.id}');

  ref.read(notificationRepositoryProvider).add(AppNotification(
        id: key,
        tier: NotificationTier.aiInsight,
        titleKey: 'report.pushTitle',
        bodyKey: 'report.pushBody',
        params: {'spent': report.spent.format(), 'cat': topCat},
        createdAt: now,
      ));
  store.setString('reports.weeklyPushed', key);
}

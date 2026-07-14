import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/life_score_service.dart';
import 'package:lifeos/features/ai/domain/ai_insight.dart';
import 'package:lifeos/features/ai/presentation/providers/ai_providers.dart';
import 'package:lifeos/features/food/presentation/pages/diet_page.dart';
import 'package:lifeos/features/food/presentation/providers/diet_providers.dart';
import 'package:lifeos/features/goals/presentation/pages/goals_page.dart';
import 'package:lifeos/features/goals/presentation/providers/goal_providers.dart';
import 'package:lifeos/features/health/presentation/pages/health_page.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/features/history/presentation/pages/history_page.dart';
import 'package:lifeos/features/history/presentation/providers/history_providers.dart';
import 'package:lifeos/features/lifeweeks/domain/life_weeks.dart';
import 'package:lifeos/features/lifeweeks/presentation/pages/life_weeks_page.dart';
import 'package:lifeos/features/home/domain/today_snapshot.dart';
import 'package:lifeos/features/home/presentation/providers/today_providers.dart';
import 'package:lifeos/features/mind/domain/mood.dart';
import 'package:lifeos/features/mind/presentation/pages/mind_page.dart';
import 'package:lifeos/features/mind/presentation/pages/mood_journal_page.dart';
import 'package:lifeos/features/mind/presentation/providers/mind_providers.dart';
import 'package:lifeos/features/mind/domain/habit_consistency.dart';
import 'package:lifeos/features/money/application/project_month_end.dart';
import 'package:lifeos/features/money/domain/entities/budget.dart';
import 'package:lifeos/features/money/presentation/widgets/add_transaction_sheet.dart';
import 'package:lifeos/features/profile/presentation/pages/profile_page.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/features/achievements/presentation/pages/achievements_page.dart';
import 'package:lifeos/features/achievements/presentation/providers/achievements_providers.dart';
import 'package:lifeos/features/backup/presentation/pages/backup_page.dart';
import 'package:lifeos/features/backup/presentation/providers/local_backup_provider.dart';
import 'package:lifeos/features/coach/presentation/pages/coach_page.dart';
import 'package:lifeos/features/coach/presentation/providers/coach_providers.dart';
import 'package:lifeos/features/insights/presentation/pages/insights_page.dart';
import 'package:lifeos/features/insights/presentation/providers/insights_providers.dart';
import 'package:lifeos/features/home/presentation/providers/today_layout_provider.dart';
import 'package:lifeos/features/search/presentation/pages/command_palette.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';
import 'package:lifeos/shared/widgets/motion.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// TODAY — the home screen. Answers the one question LifeOS exists for:
/// "given everything I know about your money, health and goals, what should you
/// do today?" Phase 1 delivers the money + Life Score answer for real.
class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  /// Maps a section id from [kTodaySections] to its card widget.
  Widget _sectionWidget(String id, TodaySnapshot snapshot, AiInsight? insight) {
    switch (id) {
      case 'quickActions':
        return const _QuickActions();
      case 'streak':
        return const _StreakCard();
      case 'coachTip':
        return const _CoachTipCard();
      case 'safeToSpend':
        return _SafeToSpendCard(budget: snapshot.budget);
      case 'lifeScore':
        return _LifeScoreCard(score: snapshot.lifeScore);
      case 'budget':
        return _BudgetBreakdown(budget: snapshot.budget);
      case 'diet':
        return const _DietCard();
      case 'health':
        return const _HealthMiniCard();
      case 'habits':
        return const _HabitsMiniCard();
      case 'tasks':
        return const _TasksMiniCard();
      case 'goal':
        return const _GoalMiniCard();
      case 'backup':
        return const _BackupNudgeCard();
      case 'ai':
        return _AiInsightCard(budget: snapshot.budget, insight: insight);
      case 'quote':
        return const _DailyQuote();
      case 'flashback':
        return const _FlashbackCard();
      case 'lifeWeeks':
        return const _LifeWeeksTeaser();
      case 'achievements':
        return const _AchievementsTeaser();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(todaySnapshotProvider);
    final insight = ref.watch(headlineInsightProvider);
    final hidden = ref.watch(todayHiddenProvider);
    final order = ref.watch(todayOrderProvider);

    var i = 0;
    final sectionWidgets = <Widget>[];
    for (final id in order) {
      if (hidden.contains(id)) continue;
      i++;
      sectionWidgets.add(FadeSlideIn(
        index: i,
        child: _sectionWidget(id, snapshot, insight),
      ));
      sectionWidgets.add(const SizedBox(height: 12));
    }

    return Scaffold(
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const FadeSlideIn(index: 0, child: _Greeting()),
            const SizedBox(height: 12),
            ...sectionWidgets,
            if (snapshot.pendingModules.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(context.tr('today.comingNext'),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...snapshot.pendingModules.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ModuleTeaserTile(teaser: m),
                  )),
            ],
          ],
        ),
        ),
      ),
    );
  }
}

class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final part = hour < 12
        ? context.tr('today.morning')
        : hour < 18
            ? context.tr('today.afternoon')
            : context.tr('today.evening');
    final name = ref.watch(profileProvider)?.name.trim() ?? '';
    final greeting = name.isEmpty ? part : '$part, $name';
    final lang = Localizations.localeOf(context).languageCode;
    var date = DateFormat.yMMMMEEEEd(lang).format(DateTime.now());
    if (date.isNotEmpty) date = date[0].toUpperCase() + date.substring(1);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: Theme.of(context).textTheme.headlineSmall),
              Text(date,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      )),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.tune),
          tooltip: context.tr('tsec.customize'),
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (_) => const _CustomizeSheet(),
          ),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.search),
          tooltip: context.tr('search.title'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CommandPalette()),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet to reorder (drag) and show/hide Today sections. Choices persist.
class _CustomizeSheet extends ConsumerWidget {
  const _CustomizeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(todayHiddenProvider);
    final order = ref.watch(todayOrderProvider);
    final vis = ref.read(todayHiddenProvider.notifier);
    final ord = ref.read(todayOrderProvider.notifier);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('tsec.title'),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(context.tr('tsec.reorderHint'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        )),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: order.length,
              onReorder: (oldIndex, newIndex) {
                // ReorderableListView reports newIndex in pre-removal terms;
                // ord.reorder expects post-removal semantics.
                if (newIndex > oldIndex) newIndex -= 1;
                ord.reorder(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final id = order[index];
                return ListTile(
                  key: ValueKey(id),
                  dense: true,
                  title: Text(context.tr(labelForSection(id))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: !hidden.contains(id),
                        onChanged: (v) => vis.setVisible(id, v),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: Icon(Icons.drag_handle,
                            color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SafeToSpendCard extends StatelessWidget {
  final Budget budget;
  const _SafeToSpendCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      colors: LifeGradients.money,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('today.safeToSpend'),
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          AnimatedCounter(
            value: budget.safeToSpendToday.major,
            format: (v) => Money.fromMajor(
              v,
              currency: budget.safeToSpendToday.currency,
            ).format(),
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            context.trp('today.leftAndDays', {
              'amount': budget.available.format(),
              'days': budget.remainingDays,
            }),
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _LifeScoreCard extends StatelessWidget {
  final LifeScore score;
  const _LifeScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          _ScoreRing(value: score.total),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('today.lifeScore'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _PillarBar(
                    label: context.tr('pillar.finance'),
                    value: score.finance),
                _PillarBar(
                    label: context.tr('pillar.health'), value: score.health),
                _PillarBar(
                    label: context.tr('pillar.discipline'),
                    value: score.discipline),
                _PillarBar(
                    label: context.tr('pillar.productivity'),
                    value: score.productivity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int value;
  const _ScoreRing({required this.value});

  @override
  Widget build(BuildContext context) {
    return GradientRing(
      progress: value / 100,
      size: 76,
      colors: LifeGradients.money,
      center: Text('$value',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800)),
    );
  }
}

class _PillarBar extends StatelessWidget {
  final String label;
  final int value;
  const _PillarBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 6,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$value', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _BudgetBreakdown extends StatelessWidget {
  final Budget budget;
  const _BudgetBreakdown({required this.budget});

  @override
  Widget build(BuildContext context) {
    // Project where the month lands if spending keeps its current pace.
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final projection = const ProjectMonthEnd()(
      income: budget.income,
      expensesSoFar: budget.expenses,
      reserve: budget.reserve,
      dayOfMonth: now.day,
      daysInMonth: daysInMonth,
    );
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('today.thisMonth'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _row(context, context.tr('money.income'), budget.income.format(),
              LifeColors.finance),
          _row(context, context.tr('money.expenses'), budget.expenses.format(),
              LifeColors.financeDanger),
          _row(context, context.tr('money.reserve'), budget.reserve.format(),
              LifeColors.goals),
          const Divider(height: 20),
          _row(context, context.tr('money.available'),
              budget.available.format(), Theme.of(context).colorScheme.primary,
              bold: true),
          if (budget.income.isPositive)
            _row(
              context,
              context.tr(
                  projection.onTrack ? 'today.projLeftover' : 'today.projOver'),
              projection.projectedLeftover.format(),
              projection.onTrack
                  ? LifeColors.finance
                  : LifeColors.financeDanger,
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, Color dot,
      {bool bold = false}) {
    final style =
        TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// A first taste of the AI Engine: deterministic, rule-based guidance derived
/// from the budget. Phase 9 swaps the body for a real model call routed through
/// the Core Engine — the card contract stays the same.
/// The dietitian's presence on Today: calories eaten vs target and the next
/// meal to have (with the cheapest store), or a profile CTA before setup.
class _DietCard extends ConsumerWidget {
  const _DietCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessment = ref.watch(assessmentProvider);

    if (assessment == null) {
      return SectionCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
        ),
        child: Row(
          children: [
            const Text('🥦', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(child: Text(context.tr('today.dietCta'))),
            const Icon(Icons.chevron_right),
          ],
        ),
      );
    }

    final eaten = ref.watch(consumedNutritionProvider);
    final next = ref.watch(nextMealProvider);
    final progress = assessment.targetKcal <= 0
        ? 0.0
        : (eaten.kcal / assessment.targetKcal).clamp(0.0, 1.0).toDouble();

    return SectionCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const DietPage()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🥦', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(context.tr('diet.title'),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Text(
                '${eaten.kcal} / ${assessment.targetKcal} '
                '${context.tr('diet.kcal')}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 8),
          ),
          const SizedBox(height: 8),
          if (next != null)
            Consumer(builder: (context, ref, _) {
              final cheapest =
                  ref.watch(mealCostCalculatorProvider).cheapest(next);
              final price = cheapest == null
                  ? ''
                  : ' · ${context.trp('diet.fromStore', {
                          'price': cheapest.$2.format(),
                          'store': context.tr('store.${cheapest.$1.id}'),
                        })}';
              return Text(
                '${context.tr('today.dietNext')}: ${next.emoji} '
                '${context.tr(next.nameKey)} · '
                '${next.nutrition.kcal} ${context.tr('diet.kcal')}$price',
                style: Theme.of(context).textTheme.bodySmall,
              );
            })
          else
            Text(context.tr('today.dietDone'),
                style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Compact health status (spec §18: Today shows health).
class _HealthMiniCard extends ConsumerWidget {
  const _HealthMiniCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(todayHealthProvider).valueOrNull;
    final score = ref.watch(healthScoreProvider);
    if (day == null) return const SizedBox.shrink();
    return SectionCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const HealthPage()),
      ),
      child: Row(
        children: [
          const Text('❤️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('nav.health'),
                    style: Theme.of(context).textTheme.titleSmall),
                Text(
                  '💧 ${day.waterGlasses}/8 · 👟 ${day.steps} · '
                  '😴 ${day.sleepHours.toStringAsFixed(1)}h',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text('$score',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Today's open tasks with inline toggles (spec §18: Today shows tasks).
/// Gentle "back up your data" nudge — shown only to engaged users (5+ tracked
/// days) who haven't backed up in the last 14 days. Data is device-local.
class _BackupNudgeCard extends ConsumerWidget {
  const _BackupNudgeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(backupStatusProvider);
    final tracked = ref.watch(insightsProvider).trackedDays;
    final stale = last == null || DateTime.now().difference(last).inDays >= 14;
    if (tracked < 5 || !stale) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const BackupPage()),
      ),
      child: GradientCard(
        colors: const [Color(0xFF396AFC), Color(0xFF2948FF)],
        child: Row(
          children: [
            const Text('💾', style: TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('today.backup.title'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(context.tr('today.backup.body'),
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

/// One-tap habit check-off for today, straight from the home screen.
class _HabitsMiniCard extends ConsumerWidget {
  const _HabitsMiniCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider).valueOrNull ?? const [];
    if (habits.isEmpty) return const SizedBox.shrink();
    final done = habits.where((h) => h.doneToday).length;
    final week = HabitConsistency.weekly(habits, DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MindPage()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('✅ ${context.tr('tsec.habits')}',
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                Text('$done/${habits.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        )),
              ],
            ),
            if (week.target > 0)
              Text(
                context.trp('tsec.habitsWeek',
                    {'n': week.completed, 'target': week.target}),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            for (final h in habits.take(4))
              Row(
                children: [
                  Checkbox(
                    value: h.doneToday,
                    visualDensity: VisualDensity.compact,
                    onChanged: (_) => ref.read(toggleHabitProvider).call(h),
                  ),
                  if (h.emoji.isNotEmpty) ...[
                    Text(h.emoji),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      h.name,
                      style: h.doneToday
                          ? TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Theme.of(context).colorScheme.outline,
                            )
                          : null,
                    ),
                  ),
                  if (h.streak > 1)
                    Text('🔥 ${h.streak}',
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            if (habits.length > 4)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: Text('+${habits.length - 4}',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

class _TasksMiniCard extends ConsumerWidget {
  const _TasksMiniCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider).valueOrNull ?? const [];
    final open = tasks.where((t) => !t.done).toList();
    if (open.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MindPage()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🧠 ${context.tr('mind.todaysTasks')}',
                style: Theme.of(context).textTheme.titleSmall),
            for (final task in open.take(3))
              Row(
                children: [
                  Checkbox(
                    value: task.done,
                    visualDensity: VisualDensity.compact,
                    onChanged: (_) =>
                        ref.read(toggleTaskProvider).call(task),
                  ),
                  Expanded(child: Text(task.title)),
                ],
              ),
            if (open.length > 3)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: Text('+${open.length - 3}',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

/// The first unfinished long-term goal (spec §18: Today shows goals).
class _GoalMiniCard extends ConsumerWidget {
  const _GoalMiniCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider).valueOrNull ?? const [];
    final active = goals.where((g) => !g.isComplete).toList();
    if (active.isEmpty) return const SizedBox.shrink();
    final goal = active.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        padding: const EdgeInsets.all(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const GoalsPage()),
        ),
        child: Row(
          children: [
            Text(goal.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.title,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        value: goal.progress, minHeight: 6),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('${(goal.progress * 100).round()}%'),
          ],
        ),
      ),
    );
  }
}

/// Shows the AI Engine's headline insight (generated through the Core Engine).
/// Falls back to a budget-derived line before the first analysis lands.
class _AiInsightCard extends StatelessWidget {
  final Budget budget;
  final AiInsight? insight;
  const _AiInsightCard({required this.budget, this.insight});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final emoji = insight?.emoji ?? '🤖';
    final title = insight == null
        ? context.tr('today.aiInsight')
        : context.tr(insight!.titleKey);
    final message = insight == null
        ? _fallback(context, budget)
        : context.trp(insight!.messageKey, insight!.params);
    return SectionCard(
      color: scheme.tertiaryContainer.withValues(alpha: 0.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fallback(BuildContext context, Budget budget) {
    if (budget.income.isZero) return context.tr('today.ai.addIncome');
    return context.trp('today.ai.onTrack', {
      'amount': budget.safeToSpendToday.format(),
      'rate': (budget.reserveRate * 100).round(),
    });
  }
}

class _ModuleTeaserTile extends StatelessWidget {
  final ModuleTeaser teaser;
  const _ModuleTeaserTile({required this.teaser});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Text(teaser.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(teaser.title,
                    style: Theme.of(context).textTheme.titleSmall),
                Text(teaser.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        )),
              ],
            ),
          ),
          Chip(
            label: const Text('Soon'),
            visualDensity: VisualDensity.compact,
            side: BorderSide.none,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}

/// "A year ago this month" — surfaces an archived snapshot so the past feels
/// alive. Hidden until there's at least a year of history.
class _FlashbackCard extends ConsumerWidget {
  const _FlashbackCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(flashbackProvider);
    if (snap == null) return const SizedBox.shrink();
    final yearsAgo = DateTime.now().year - snap.year;
    final parts = <String>[
      if (snap.spentMinor > 0) '−${Money(snap.spentMinor).format()}',
      if (snap.avgMood != null) moodFace(snap.avgMood!.round()),
      if (snap.avgSteps > 0) '👟 ${snap.avgSteps}',
    ];
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const HistoryPage()),
      ),
      child: GradientCard(
        colors: LifeGradients.mind,
        child: Row(
          children: [
            const Text('🕰️', style: TextStyle(fontSize: 34)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    yearsAgo <= 1
                        ? context.tr('hist.flashback')
                        : context.trp('hist.flashbackN', {'n': yearsAgo}),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                  if (parts.isNotEmpty)
                    Text(parts.join('  ·  '),
                        style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

/// One-tap logging shortcuts at the top of Today.
class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget action(String emoji, String label, VoidCallback onTap) => Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(label,
                      style: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
    return SectionCard(
      child: Row(
        children: [
          action('💧', context.tr('qa.water'),
              () => ref.read(logHealthProvider).addWater()),
          action('💸', context.tr('qa.expense'),
              () => AddTransactionSheet.show(context)),
          action('✅', context.tr('qa.task'),
              () => _addTask(context, ref)),
          action('📔', context.tr('qa.mood'), () {
            Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const MoodJournalPage()));
          }),
        ],
      ),
    );
  }

  Future<void> _addTask(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('mind.newTask')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: ctx.tr('mind.whatToDo')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(ctx.tr('common.add'))),
        ],
      ),
    );
    if (title != null && title.trim().isNotEmpty) {
      ref.read(addTaskProvider).call(title);
    }
  }
}

/// A rotating daily motivational line.
class _DailyQuote extends StatelessWidget {
  const _DailyQuote();

  static const _keys = [
    'quote.1', 'quote.2', 'quote.3', 'quote.4', 'quote.5',
    'quote.6', 'quote.7', 'quote.8',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final key = _keys[now.difference(DateTime(now.year)).inDays % _keys.length];
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('“', style: TextStyle(fontSize: 28, height: 1)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(context.tr(key),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}

/// A compact "life in weeks" teaser — makes the signature feature discoverable
/// and adds a little existential spark to the home screen.
class _LifeWeeksTeaser extends ConsumerWidget {
  const _LifeWeeksTeaser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    if (profile == null) return const SizedBox.shrink();
    final life = LifeWeeks(ageYears: profile.age);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LifeWeeksPage()),
      ),
      child: GradientCard(
        colors: const [Color(0xFF7F53AC), Color(0xFF647DEE)],
        child: Row(
          children: [
            const Text('⏳', style: TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('weeks.title'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    context.trp('weeks.teaser', {
                      'pct': life.percentLived,
                      'left': life.weeksLeft,
                    }),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: life.fractionLived,
                      minHeight: 6,
                      color: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

/// "You've shown up N days in a row" — an engagement streak. Hidden until a
/// streak of 2+ builds so it never nags a new user.
class _StreakCard extends ConsumerWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(insightsProvider).loggingStreak;
    if (streak < 2) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const InsightsPage()),
      ),
      child: GradientCard(
        colors: const [Color(0xFFF83600), Color(0xFFFE8C00)],
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 34)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.trp('today.streak.title', {'n': streak}),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(context.tr('today.streak.body'),
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Proactive coach tip: the single most relevant nudge from the AI coach,
/// chosen from the user's own data. Tap to open the full chat.
class _CoachTipCard extends ConsumerWidget {
  const _CoachTipCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tip = ref.watch(coachTipProvider);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CoachPage()),
      ),
      child: SectionCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🤖', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('coach.tipTitle').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(context.trp(tip.messageKey, tip.params),
                      style: const TextStyle(height: 1.35)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(context.tr('coach.tipCta'),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary)),
                      Icon(Icons.chevron_right,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Teaser: how many badges are unlocked + the one you're closest to earning.
class _AchievementsTeaser extends ConsumerWidget {
  const _AchievementsTeaser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(achievementsProvider);
    if (all.isEmpty) return const SizedBox.shrink();
    final unlocked = all.where((s) => s.unlocked).length;
    final next = ref.watch(nextAchievementProvider);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AchievementsPage()),
      ),
      child: GradientCard(
        colors: const [Color(0xFFF7971E), Color(0xFFFFD200)],
        child: Row(
          children: [
            const Text('🏅', style: TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('ach.title'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    context.trp(
                        'ach.unlockedOf', {'n': unlocked, 'total': all.length}),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (next != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      context.trp('ach.teaserNext', {
                        'name': '${next.def.emoji} ${context.tr(next.def.titleKey)}',
                      }),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: next.ratio,
                        minHeight: 6,
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

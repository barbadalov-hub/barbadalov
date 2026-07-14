import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/goals/application/forecast_goal.dart';
import 'package:lifeos/features/goals/domain/entities/goal.dart';
import 'package:lifeos/features/goals/presentation/providers/goal_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('nav.goals'))),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-goals',
        onPressed: () => _addGoalDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(context.tr('goals.goal')),
      ),
      body: AnimatedBackdrop(
        style: BackdropStyle.orbs,
        color: LifeColors.goals,
        child: goals.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (list) {
            if (list.isEmpty) {
              return Center(child: Text(context.tr('goals.none')));
            }
            // Active goals first (by progress), completed ones at the bottom.
            final sorted = [...list]..sort((a, b) {
                if (a.isComplete != b.isComplete) return a.isComplete ? 1 : -1;
                return b.progress.compareTo(a.progress);
              });
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _GoalsSummary(goals: list),
                const SizedBox(height: 12),
                for (final g in sorted) ...[
                  _GoalCard(goal: g),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _addGoalDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('goals.newGoal')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: ctx.tr('goals.title')),
            ),
            TextField(
              controller: targetController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  InputDecoration(labelText: ctx.tr('goals.targetAmount')),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr('common.create'))),
        ],
      ),
    );
    if (ok != true) return;
    final target =
        double.tryParse(targetController.text.replaceAll(',', '.')) ?? 0;
    ref.read(addGoalProvider).call(
          title: titleController.text,
          target: Money.fromMajor(target),
        );
  }
}

/// Overall progress across every goal.
class _GoalsSummary extends StatelessWidget {
  final List<Goal> goals;
  const _GoalsSummary({required this.goals});

  @override
  Widget build(BuildContext context) {
    final saved = goals.fold(0, (s, g) => s + g.saved.minorUnits);
    final target = goals.fold(0, (s, g) => s + g.target.minorUnits);
    final done = goals.where((g) => g.isComplete).length;
    final ratio = target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0);
    return SectionCard(
      color: LifeColors.goals.withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('goals.overall'),
                  style: Theme.of(context).textTheme.titleMedium),
              Text('${(ratio * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          Text('${Money(saved).format()} / ${Money(target).format()}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
                value: ratio.toDouble(),
                minHeight: 8,
                color: LifeColors.goals),
          ),
          const SizedBox(height: 6),
          Text(
            context.trp('goals.summaryLine',
                {'total': goals.length, 'done': done}),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final Goal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecast = ref.watch(goalForecastProvider(goal));
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(goal.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(goal.title,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Text('${(goal.progress * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: goal.progress, minHeight: 8),
          ),
          const SizedBox(height: 8),
          Text(context.trp('goals.ofTarget', {
            'saved': goal.saved.format(),
            'target': goal.target.format(),
            'remaining': goal.remaining.format(),
          })),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _forecastLine(context, forecast)),
              TextButton.icon(
                onPressed: () => _contributeDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: Text(context.tr('common.add')),
              ),
            ],
          ),
          if (!goal.isComplete)
            Wrap(
              spacing: 8,
              children: [
                for (final amount in const [10, 50, 100])
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    label: Text('+${Money.fromMajor(amount).format()}'),
                    onPressed: () => ref
                        .read(contributeToGoalProvider)
                        .call(goal, Money.fromMajor(amount)),
                  ),
              ],
            ),
          if (goal.milestones.isNotEmpty) ...[
            const Divider(height: 16),
            for (var i = 0; i < goal.milestones.length; i++)
              InkWell(
                onTap: () => ref.read(toggleMilestoneProvider).call(goal, i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        goal.milestones[i].done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: goal.milestones[i].done
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          goal.milestones[i].title,
                          style: TextStyle(
                            decoration: goal.milestones[i].done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addMilestoneDialog(context, ref),
              icon: const Icon(Icons.flag_outlined, size: 16),
              label: Text(context.tr('goals.addStage')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMilestoneDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('goals.newStage')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: ctx.tr('goals.stageTitle')),
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
    if (title == null || title.trim().isEmpty) return;
    ref.read(addMilestoneProvider).call(goal, title);
  }

  Widget _forecastLine(BuildContext context, GoalForecast f) {
    final style = Theme.of(context).textTheme.bodySmall;
    if (f.complete) {
      return Text(context.tr('goals.reached'), style: style);
    }
    final Widget main;
    if (f.monthsRemaining == null) {
      main = Text(context.tr('goals.saveMonthly'), style: style);
    } else {
      final date = DateFormat.yMMM().format(f.projectedDate!);
      final flag = f.onTrackForTargetDate
          ? '✅ ${context.tr('goals.onTrack')}'
          : '⚠️ ${context.tr('goals.behind')}';
      main = Text(
        context.trp('goals.forecast', {
          'months': f.monthsRemaining!,
          'date': date,
          'flag': flag,
        }),
        style: style,
      );
    }
    // When the goal has a deadline it isn't on pace for, show the monthly
    // contribution needed to still make it.
    final required = f.requiredMonthly;
    if (required != null && !f.onTrackForTargetDate) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          main,
          Text(
            context.trp('goals.needMonthly', {'amount': required.format()}),
            style: style?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      );
    }
    return main;
  }

  Future<void> _contributeDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.trp('goals.addTo', {'title': goal.title})),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '\$ '),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(
                ctx, double.tryParse(controller.text.replaceAll(',', '.'))),
            child: Text(ctx.tr('common.add')),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    ref.read(contributeToGoalProvider).call(goal, Money.fromMajor(amount));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/mind/presentation/providers/mind_providers.dart';
import 'package:lifeos/features/mind/presentation/widgets/habit_heatmap.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// A single habit: streak, weekly target progress, and a completion heatmap.
class HabitDetailPage extends ConsumerWidget {
  final String habitId;
  const HabitDetailPage({required this.habitId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider).valueOrNull ?? const [];
    final habit = habits.where((h) => h.id == habitId).firstOrNull;
    if (habit == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final now = ref.watch(clockProvider).now();

    return Scaffold(
      appBar: AppBar(title: Text('${habit.emoji}  ${habit.name}')),
      body: AnimatedBackdrop(
        style: BackdropStyle.orbs,
        color: const Color(0xFF7F53AC),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            GradientCard(
              colors: LifeGradients.mind,
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 34)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.trp('habit.streak', {'n': habit.streak}),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        Text(
                          habit.isFlexible
                              ? context.trp('habit.weekProgress', {
                                  'n': habit.completionsThisWeek(now),
                                  'target': habit.targetPerWeek,
                                })
                              : context.tr('habit.daily'),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('habit.heatmap'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  HabitHeatmap(
                    completedDates: habit.completedDates,
                    now: now,
                    color: const Color(0xFF7F53AC),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.trp('habit.total',
                        {'n': habit.completedDates.length}),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: Icon(habit.doneToday ? Icons.undo : Icons.check),
                label: Text(habit.doneToday
                    ? context.tr('habit.markUndone')
                    : context.tr('habit.markDone')),
                onPressed: () => ref.read(toggleHabitProvider).call(habit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/health/domain/entities/workout_program.dart';
import 'package:lifeos/features/health/presentation/pages/gym_session_page.dart';
import 'package:lifeos/features/health/presentation/pages/workouts_page.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// A ready-made routine: header (goal/level/duration) + its exercises, each
/// opening the shared technique sheet. "Done" logs the whole session.
class ProgramDetailPage extends ConsumerWidget {
  final WorkoutProgram program;
  const ProgramDetailPage({required this.program, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = program.exercises;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(program.nameKey))),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-workouts',
        onPressed: () {
          ref.read(logHealthProvider).completeWorkout('program-${program.id}');
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(context.tr('prog.logged'))));
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.check),
        label: Text(context.tr('prog.finish')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          GradientCard(
            colors: LifeGradients.health,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${program.emoji}  ${context.tr(program.nameKey)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text(context.tr(program.descKey),
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(context.tr('prog.goal.${program.goal}')),
                    _pill(context.tr('prog.level.${program.level}')),
                    _pill('${program.durationMin} ${context.tr('prog.min')}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (exercises.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.fitness_center),
                label: Text(context.tr('gym.start')),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => GymSessionPage(program: program)),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(context.tr('prog.exercises'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (exercises.isEmpty)
            SectionCard(child: Text(context.tr('wo.noDesc')))
          else
            for (final w in exercises)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CuratedWorkoutCard(workout: w),
              ),
          const SizedBox(height: 12),
          Text(context.tr('guide.sheetWarn'),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: LifeColors.goals)),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      );
}

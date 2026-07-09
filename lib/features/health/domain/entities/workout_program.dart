import 'package:lifeos/features/health/domain/entities/workout.dart';

/// A ready-made routine: a themed sequence of exercises with a level, goal and
/// rough duration. Groups the exercise catalog into something you can just
/// open and follow.
class WorkoutProgram {
  final String id;
  final String emoji;
  final String nameKey;
  final String descKey;
  final String level; // beginner | inter | advanced (i18n suffix)
  final String goal; // strength | fatloss | core | general (i18n suffix)
  final int durationMin;
  final List<String> exerciseIds;

  const WorkoutProgram({
    required this.id,
    required this.emoji,
    required this.nameKey,
    required this.descKey,
    required this.level,
    required this.goal,
    required this.durationMin,
    required this.exerciseIds,
  });

  /// Resolved exercises from the catalog (skips any unknown id).
  List<Workout> get exercises => [
        for (final id in exerciseIds)
          if (WorkoutCatalog.byId(id) case final w?) w,
      ];
}

class WorkoutProgramCatalog {
  const WorkoutProgramCatalog._();

  static const all = <WorkoutProgram>[
    WorkoutProgram(
      id: 'fullbody',
      emoji: '🔥',
      nameKey: 'prog.fullbody',
      descKey: 'prog.fullbody.desc',
      level: 'beginner',
      goal: 'strength',
      durationMin: 30,
      exerciseIds: [
        'squat', 'pushup', 'plank_row', 'lunges', 'glute_bridge', 'crunches',
      ],
    ),
    WorkoutProgram(
      id: 'home',
      emoji: '🏠',
      nameKey: 'prog.home',
      descKey: 'prog.home.desc',
      level: 'beginner',
      goal: 'general',
      durationMin: 20,
      exerciseIds: ['pushup', 'squat', 'plank', 'superman', 'glute_bridge'],
    ),
    WorkoutProgram(
      id: 'core',
      emoji: '🧘',
      nameKey: 'prog.core',
      descKey: 'prog.core.desc',
      level: 'inter',
      goal: 'core',
      durationMin: 15,
      exerciseIds: ['plank', 'crunches', 'mountain_climber', 'superman'],
    ),
    WorkoutProgram(
      id: 'hiit',
      emoji: '⚡',
      nameKey: 'prog.hiit',
      descKey: 'prog.hiit.desc',
      level: 'inter',
      goal: 'fatloss',
      durationMin: 20,
      exerciseIds: [
        'jumping_jack', 'mountain_climber', 'squat', 'pushup', 'lunges',
      ],
    ),
    WorkoutProgram(
      id: 'strength',
      emoji: '💪',
      nameKey: 'prog.strength',
      descKey: 'prog.strength.desc',
      level: 'advanced',
      goal: 'strength',
      durationMin: 40,
      exerciseIds: [
        'kb_deadlift', 'squat', 'floor_dips', 'plank_row', 'lunges',
      ],
    ),
  ];
}

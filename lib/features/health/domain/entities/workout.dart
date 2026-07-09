import 'package:equatable/equatable.dart';

/// An exercise in the workout catalog: localized name/technique via i18n keys,
/// a real illustration from the open-source **wger** exercise database
/// (CC-licensed, loaded lazily over the network with an emoji fallback), and a
/// video looked up on demand — nothing is downloaded until the user asks.
class Workout extends Equatable {
  final String id;
  final String emoji;
  final String nameKey;
  final String musclesKey;
  final String setsReps;
  final List<String> stepKeys;
  final String imageUrl;

  const Workout({
    required this.id,
    required this.emoji,
    required this.nameKey,
    required this.musclesKey,
    required this.setsReps,
    required this.stepKeys,
    required this.imageUrl,
  });

  @override
  List<Object?> get props =>
      [id, emoji, nameKey, musclesKey, setsReps, stepKeys, imageUrl];
}

/// Curated home/gym basics. Image URLs verified live against wger.de.
class WorkoutCatalog {
  const WorkoutCatalog._();

  static const all = <Workout>[
    Workout(
      id: 'squat',
      emoji: '🏋️',
      nameKey: 'wo.squat',
      musclesKey: 'wo.squat.muscles',
      setsReps: '4 × 12',
      stepKeys: ['wo.squat.s1', 'wo.squat.s2', 'wo.squat.s3'],
      imageUrl:
          'https://wger.de/media/exercise-images/1963/db285682-1ab3-4be0-ae00-5117ecce1ee6.png',
    ),
    Workout(
      id: 'lunges',
      emoji: '🦵',
      nameKey: 'wo.lunges',
      musclesKey: 'wo.lunges.muscles',
      setsReps: '3 × 10',
      stepKeys: ['wo.lunges.s1', 'wo.lunges.s2', 'wo.lunges.s3'],
      imageUrl:
          'https://wger.de/media/exercise-images/984/5c7ffe68-e7b2-47f3-a22a-f9cc28640432.png',
    ),
    Workout(
      id: 'crunches',
      emoji: '🧘',
      nameKey: 'wo.crunches',
      musclesKey: 'wo.crunches.muscles',
      setsReps: '3 × 15',
      stepKeys: ['wo.crunches.s1', 'wo.crunches.s2', 'wo.crunches.s3'],
      imageUrl: 'https://wger.de/media/exercise-images/91/Crunches-1.png',
    ),
    Workout(
      id: 'floor_dips',
      emoji: '💪',
      nameKey: 'wo.floorDips',
      musclesKey: 'wo.floorDips.muscles',
      setsReps: '3 × 12',
      stepKeys: ['wo.floorDips.s1', 'wo.floorDips.s2', 'wo.floorDips.s3'],
      imageUrl:
          'https://wger.de/media/exercise-images/1000/553266a8-a972-48c5-a014-b12afac66f65.png',
    ),
    Workout(
      id: 'plank_row',
      emoji: '🤸',
      nameKey: 'wo.plankRow',
      musclesKey: 'wo.plankRow.muscles',
      setsReps: '3 × 8',
      stepKeys: ['wo.plankRow.s1', 'wo.plankRow.s2', 'wo.plankRow.s3'],
      imageUrl:
          'https://wger.de/media/exercise-images/1022/f74644fa-f43e-46bd-8603-6e3a2ee8ee2d.jpg',
    ),
    Workout(
      id: 'kb_deadlift',
      emoji: '🏋️‍♀️',
      nameKey: 'wo.kbDeadlift',
      musclesKey: 'wo.kbDeadlift.muscles',
      setsReps: '4 × 10',
      stepKeys: ['wo.kbDeadlift.s1', 'wo.kbDeadlift.s2', 'wo.kbDeadlift.s3'],
      imageUrl:
          'https://wger.de/media/exercise-images/1003/772d6e47-3865-4944-9255-7435d0b06782.png',
    ),
    // --- Bodyweight basics (emoji illustration; no equipment) --------------
    Workout(
      id: 'pushup',
      emoji: '🤲',
      nameKey: 'wo.pushup',
      musclesKey: 'wo.pushup.muscles',
      setsReps: '3 × 12',
      stepKeys: ['wo.pushup.s1', 'wo.pushup.s2', 'wo.pushup.s3'],
      imageUrl: '',
    ),
    Workout(
      id: 'plank',
      emoji: '🧎',
      nameKey: 'wo.plank',
      musclesKey: 'wo.plank.muscles',
      setsReps: '3 × 45s',
      stepKeys: ['wo.plank.s1', 'wo.plank.s2', 'wo.plank.s3'],
      imageUrl: '',
    ),
    Workout(
      id: 'glute_bridge',
      emoji: '🍑',
      nameKey: 'wo.gluteBridge',
      musclesKey: 'wo.gluteBridge.muscles',
      setsReps: '3 × 15',
      stepKeys: ['wo.gluteBridge.s1', 'wo.gluteBridge.s2', 'wo.gluteBridge.s3'],
      imageUrl: '',
    ),
    Workout(
      id: 'mountain_climber',
      emoji: '⛰️',
      nameKey: 'wo.mountainClimber',
      musclesKey: 'wo.mountainClimber.muscles',
      setsReps: '3 × 30s',
      stepKeys: [
        'wo.mountainClimber.s1',
        'wo.mountainClimber.s2',
        'wo.mountainClimber.s3',
      ],
      imageUrl: '',
    ),
    Workout(
      id: 'jumping_jack',
      emoji: '🤸‍♂️',
      nameKey: 'wo.jumpingJack',
      musclesKey: 'wo.jumpingJack.muscles',
      setsReps: '3 × 40',
      stepKeys: [
        'wo.jumpingJack.s1',
        'wo.jumpingJack.s2',
        'wo.jumpingJack.s3',
      ],
      imageUrl: '',
    ),
    Workout(
      id: 'superman',
      emoji: '🦸',
      nameKey: 'wo.superman',
      musclesKey: 'wo.superman.muscles',
      setsReps: '3 × 15',
      stepKeys: ['wo.superman.s1', 'wo.superman.s2', 'wo.superman.s3'],
      imageUrl: '',
    ),
  ];

  /// Lookup by id (used by workout programs).
  static Workout? byId(String id) {
    for (final w in all) {
      if (w.id == id) return w;
    }
    return null;
  }
}

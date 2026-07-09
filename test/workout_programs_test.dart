import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/health/domain/entities/workout.dart';
import 'package:lifeos/features/health/domain/entities/workout_program.dart';

void main() {
  test('WorkoutCatalog.byId finds and misses correctly', () {
    expect(WorkoutCatalog.byId('squat')?.id, 'squat');
    expect(WorkoutCatalog.byId('nope'), isNull);
  });

  test('every program references only real exercises and is non-empty', () {
    for (final p in WorkoutProgramCatalog.all) {
      expect(p.exerciseIds, isNotEmpty, reason: '${p.id} has no exercises');
      expect(p.exercises.length, p.exerciseIds.length,
          reason: '${p.id} references an unknown exercise id');
    }
  });

  test('program ids are unique', () {
    final ids = WorkoutProgramCatalog.all.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}

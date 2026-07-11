import 'package:equatable/equatable.dart';
import 'package:lifeos/features/mind/domain/entities/habit.dart';

/// Adherence to habit targets for the current week, aggregated across habits.
class WeeklyConsistency extends Equatable {
  /// Completions this week, each habit capped at its own weekly target so
  /// over-doing one habit can't mask skipping another.
  final int completed;

  /// Sum of every habit's weekly target.
  final int target;

  const WeeklyConsistency({required this.completed, required this.target});

  /// Adherence as a 0–100 percentage (0 when there are no targets).
  int get pct =>
      target <= 0 ? 0 : (completed * 100 / target).round().clamp(0, 100);

  @override
  List<Object?> get props => [completed, target];
}

/// Aggregates weekly habit adherence — a single "how's this week going" number
/// for the whole habit list. Pure and deterministic.
class HabitConsistency {
  const HabitConsistency._();

  static WeeklyConsistency weekly(List<Habit> habits, DateTime now) {
    var completed = 0;
    var target = 0;
    for (final h in habits) {
      final t = h.targetPerWeek;
      final done = h.completionsThisWeek(now);
      completed += done < t ? done : t; // cap each habit at its target
      target += t;
    }
    return WeeklyConsistency(completed: completed, target: target);
  }
}

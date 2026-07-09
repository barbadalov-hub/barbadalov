import 'dart:async';

import 'package:lifeos/features/goals/domain/entities/goal.dart';
import 'package:lifeos/features/goals/domain/repositories/goal_repository.dart';

class GoalRepositoryImpl implements GoalRepository {
  GoalRepositoryImpl({List<Goal> seed = const [], this.onChanged})
      : _goals = List.of(seed);

  final List<Goal> _goals;
  final void Function(List<Goal> items)? onChanged;
  final StreamController<List<Goal>> _controller =
      StreamController<List<Goal>>.broadcast();

  @override
  void add(Goal goal) {
    _goals.add(goal);
    _emit();
    onChanged?.call(all());
  }

  @override
  void update(Goal goal) {
    final i = _goals.indexWhere((g) => g.id == goal.id);
    if (i == -1) return;
    _goals[i] = goal;
    _emit();
    onChanged?.call(all());
  }

  @override
  List<Goal> all() => List.unmodifiable(_goals);

  @override
  Stream<List<Goal>> watch() async* {
    yield all();
    yield* _controller.stream;
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(all());
  }

  Future<void> dispose() => _controller.close();
}

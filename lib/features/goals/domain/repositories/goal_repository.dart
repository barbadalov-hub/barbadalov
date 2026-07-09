import 'package:lifeos/features/goals/domain/entities/goal.dart';

abstract class GoalRepository {
  void add(Goal goal);
  void update(Goal goal);
  List<Goal> all();
  Stream<List<Goal>> watch();
}

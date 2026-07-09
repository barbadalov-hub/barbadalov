import 'package:lifeos/core/events/life_event.dart';

class GoalCreatedEvent extends LifeEvent {
  final String goalId;
  final String title;
  final int targetMinorUnits;

  const GoalCreatedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required this.goalId,
    required this.title,
    required this.targetMinorUnits,
  });

  @override
  String get type => 'goal_created';

  @override
  Map<String, dynamic> toPayload() =>
      {'goalId': goalId, 'title': title, 'targetMinorUnits': targetMinorUnits};
}

class GoalUpdatedEvent extends LifeEvent {
  final String goalId;
  final int savedMinorUnits;

  const GoalUpdatedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required this.goalId,
    required this.savedMinorUnits,
  });

  @override
  String get type => 'goal_updated';

  @override
  Map<String, dynamic> toPayload() =>
      {'goalId': goalId, 'savedMinorUnits': savedMinorUnits};
}

import 'package:lifeos/core/events/life_event.dart';

class HabitCompletedEvent extends LifeEvent {
  final String habitId;
  final bool completed;

  const HabitCompletedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required this.habitId,
    required this.completed,
  });

  @override
  String get type => 'habit_completed';

  @override
  Map<String, dynamic> toPayload() =>
      {'habitId': habitId, 'completed': completed};
}

class TaskCompletedEvent extends LifeEvent {
  final String taskId;
  final bool completed;

  const TaskCompletedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required this.taskId,
    required this.completed,
  });

  @override
  String get type => 'task_completed';

  @override
  Map<String, dynamic> toPayload() =>
      {'taskId': taskId, 'completed': completed};
}

class BookProgressEvent extends LifeEvent {
  final String bookId;
  final int currentPage;

  const BookProgressEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required this.bookId,
    required this.currentPage,
  });

  @override
  String get type => 'book_progress';

  @override
  Map<String, dynamic> toPayload() =>
      {'bookId': bookId, 'currentPage': currentPage};
}

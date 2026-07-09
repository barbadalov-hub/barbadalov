import 'package:equatable/equatable.dart';

/// A task for today. (Named `DayTask` to avoid clashing with the harness/task
/// tooling and with `dart:async`'s scheduling vocabulary.)
class DayTask extends Equatable {
  final String id;
  final String title;
  final bool done;

  const DayTask({
    required this.id,
    required this.title,
    this.done = false,
  });

  DayTask toggle() => DayTask(id: id, title: title, done: !done);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  factory DayTask.fromJson(Map<String, dynamic> json) => DayTask(
        id: json['id'] as String,
        title: json['title'] as String,
        done: (json['done'] as bool?) ?? false,
      );

  @override
  List<Object?> get props => [id, title, done];
}

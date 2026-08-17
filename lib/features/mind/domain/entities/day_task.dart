import 'package:equatable/equatable.dart';

/// A task for today. (Named `DayTask` to avoid clashing with the harness/task
/// tooling and with `dart:async`'s scheduling vocabulary.)
class DayTask extends Equatable {
  final String id;
  final String title;
  final bool done;

  /// Minutes from midnight when this is meant to happen, or null for "some time
  /// today". The planner lays timed tasks out on the hour rail; untimed ones
  /// stay in a loose list, so adding a clock never becomes mandatory.
  final int? atMinutes;

  /// Whether to nudge with a phone notification at [atMinutes]. Meaningless
  /// without a time, so it is forced off when the time is cleared.
  final bool notify;

  const DayTask({
    required this.id,
    required this.title,
    this.done = false,
    this.atMinutes,
    this.notify = false,
  });

  bool get isTimed => atMinutes != null;

  /// Hour of day (0–23), or null when untimed.
  int? get hour => atMinutes == null ? null : atMinutes! ~/ 60;

  /// `"08:05"` for display; empty when untimed.
  String get timeLabel {
    if (atMinutes == null) return '';
    final h = (atMinutes! ~/ 60).toString().padLeft(2, '0');
    final m = (atMinutes! % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// A stable positive notification id derived from the task id.
  int get notificationId => id.hashCode & 0x7fffffff;

  DayTask toggle() => copyWith(done: !done);

  DayTask copyWith({
    String? title,
    bool? done,
    int? atMinutes,
    bool? notify,
    bool clearTime = false,
  }) {
    final time = clearTime ? null : (atMinutes ?? this.atMinutes);
    return DayTask(
      id: id,
      title: title ?? this.title,
      done: done ?? this.done,
      atMinutes: time,
      // A bell without a time would never ring.
      notify: time == null ? false : (notify ?? this.notify),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'done': done,
        'atMinutes': atMinutes,
        'notify': notify,
      };

  factory DayTask.fromJson(Map<String, dynamic> json) => DayTask(
        id: json['id'] as String,
        title: json['title'] as String,
        done: (json['done'] as bool?) ?? false,
        atMinutes: (json['atMinutes'] as num?)?.toInt(),
        notify: (json['notify'] as bool?) ?? false,
      );

  @override
  List<Object?> get props => [id, title, done, atMinutes, notify];
}

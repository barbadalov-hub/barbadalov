import 'package:equatable/equatable.dart';
import 'package:lifeos/shared/models/money.dart';

/// A single checkpoint on the way to a goal.
class Milestone extends Equatable {
  final String title;
  final bool done;
  const Milestone({required this.title, this.done = false});

  Milestone toggle() => Milestone(title: title, done: !done);

  Map<String, dynamic> toJson() => {'title': title, 'done': done};
  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
        title: json['title'] as String,
        done: (json['done'] as bool?) ?? false,
      );

  @override
  List<Object?> get props => [title, done];
}

/// A long-term goal (move city, savings target, etc.) with money progress, an
/// optional target date, and a list of milestones/stages.
class Goal extends Equatable {
  final String id;
  final String title;
  final String emoji;
  final Money target;
  final Money saved;
  final DateTime? targetDate;
  final List<Milestone> milestones;

  const Goal({
    required this.id,
    required this.title,
    required this.emoji,
    required this.target,
    required this.saved,
    this.targetDate,
    this.milestones = const [],
  });

  double get progress {
    if (target.minorUnits <= 0) return 0;
    return (saved.minorUnits / target.minorUnits).clamp(0.0, 1.0).toDouble();
  }

  Money get remaining => (target - saved).clampToZero();
  bool get isComplete => saved >= target;

  int get milestonesDone => milestones.where((m) => m.done).length;

  Goal _copy({Money? saved, List<Milestone>? milestones}) => Goal(
        id: id,
        title: title,
        emoji: emoji,
        target: target,
        saved: saved ?? this.saved,
        targetDate: targetDate,
        milestones: milestones ?? this.milestones,
      );

  Goal contribute(Money amount) => _copy(saved: saved + amount);

  Goal addMilestone(String title) =>
      _copy(milestones: [...milestones, Milestone(title: title.trim())]);

  Goal toggleMilestone(int index) => _copy(milestones: [
        for (var i = 0; i < milestones.length; i++)
          if (i == index) milestones[i].toggle() else milestones[i],
      ]);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'targetMinor': target.minorUnits,
        'currency': target.currency,
        'savedMinor': saved.minorUnits,
        'targetDate': targetDate?.toIso8601String(),
        'milestones': milestones.map((m) => m.toJson()).toList(),
      };

  factory Goal.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'] as String;
    final rawMilestones = (json['milestones'] as List<dynamic>?) ?? const [];
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      emoji: json['emoji'] as String,
      target: Money(json['targetMinor'] as int, currency: currency),
      saved: Money(json['savedMinor'] as int, currency: currency),
      targetDate: json['targetDate'] == null
          ? null
          : DateTime.parse(json['targetDate'] as String),
      milestones: rawMilestones
          .map((e) => Milestone.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props =>
      [id, title, emoji, target, saved, targetDate, milestones];
}

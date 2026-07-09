import 'package:equatable/equatable.dart';

class Habit extends Equatable {
  final String id;
  final String name;
  final String emoji;

  /// Derived-and-cached: whether it's done for the current day and the current
  /// consecutive-day streak. Kept as fields (many widgets read them) but always
  /// recomputed from [completedDates] via [refreshedFor]/[toggledOn].
  final bool doneToday;
  final int streak;

  /// Day-precision completion history — powers the heatmap and correct streaks.
  final List<DateTime> completedDates;

  /// Target completions per week (7 = a daily habit; <7 = flexible schedule).
  final int targetPerWeek;

  const Habit({
    required this.id,
    required this.name,
    required this.emoji,
    this.doneToday = false,
    this.streak = 0,
    this.completedDates = const [],
    this.targetPerWeek = 7,
  });

  bool get isFlexible => targetPerWeek < 7;

  bool doneOn(DateTime day) => completedDates.any((d) => _sameDay(d, day));

  /// Completions in the current Mon–Sun week up to [now].
  int completionsThisWeek(DateTime now) {
    final today = _dateOnly(now);
    final monday = today.subtract(Duration(days: now.weekday - 1));
    return completedDates.where((d) {
      final x = _dateOnly(d);
      return !x.isBefore(monday) && !x.isAfter(today);
    }).length;
  }

  /// Toggle completion for [day] (add if absent, remove if present), then
  /// recompute the cached streak / doneToday.
  Habit toggledOn(DateTime day) {
    final next = doneOn(day)
        ? [for (final d in completedDates) if (!_sameDay(d, day)) d]
        : [...completedDates, _dateOnly(day)];
    return _copy(completedDates: next).refreshedFor(day);
  }

  /// Recompute [doneToday]/[streak] for a given "now" (e.g. on app load, so a
  /// habit done yesterday no longer shows as done today).
  Habit refreshedFor(DateTime now) => _copy(
        doneToday: doneOn(now),
        streak: _streakAsOf(completedDates, now),
      );

  static int _streakAsOf(List<DateTime> dates, DateTime asOf) {
    if (dates.isEmpty) return 0;
    final days = {for (final d in dates) _dateOnly(d)};
    var cursor = _dateOnly(asOf);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0; // broken before yesterday
    }
    var n = 0;
    while (days.contains(cursor)) {
      n++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return n;
  }

  Habit _copy({
    bool? doneToday,
    int? streak,
    List<DateTime>? completedDates,
    int? targetPerWeek,
  }) =>
      Habit(
        id: id,
        name: name,
        emoji: emoji,
        doneToday: doneToday ?? this.doneToday,
        streak: streak ?? this.streak,
        completedDates: completedDates ?? this.completedDates,
        targetPerWeek: targetPerWeek ?? this.targetPerWeek,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'doneToday': doneToday,
        'streak': streak,
        'completedDates': [
          for (final d in completedDates) _dateOnly(d).toIso8601String(),
        ],
        'targetPerWeek': targetPerWeek,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        doneToday: (json['doneToday'] as bool?) ?? false,
        streak: (json['streak'] as int?) ?? 0,
        completedDates: [
          for (final d in (json['completedDates'] as List? ?? []))
            DateTime.parse('$d'),
        ],
        targetPerWeek: (json['targetPerWeek'] as num?)?.toInt() ?? 7,
      );

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  List<Object?> get props =>
      [id, name, emoji, doneToday, streak, completedDates, targetPerWeek];
}

/// A kind of training, with roughly how hard it is.
///
/// The multiplier is a MET-style factor against brisk walking, used only to
/// turn minutes into a rough calorie figure. It is deliberately coarse: an
/// honest approximation beats a precise-looking number that is equally wrong.
enum ActivityKind {
  walk('act.walk', '🚶', 1.0),
  run('act.run', '🏃', 2.4),
  gym('act.gym', '🏋️', 1.8),
  cycling('act.cycling', '🚴', 2.0),
  swim('act.swim', '🏊', 2.3),
  yoga('act.yoga', '🧘', 0.8),
  team('act.team', '⚽', 2.1),
  other('act.other', '🤸', 1.4);

  const ActivityKind(this.labelKey, this.emoji, this.intensity);

  final String labelKey;
  final String emoji;
  final double intensity;

  static ActivityKind fromName(String name) => values.firstWhere(
        (k) => k.name == name,
        orElse: () => ActivityKind.other,
      );
}

/// One training session that actually happened.
///
/// Kept as separate entries rather than a running daily total, because the
/// whole point of the request was being able to take one back: a total cannot
/// tell you which forty minutes were the mistaken tap.
class ActivityEntry {
  final String id;
  final ActivityKind kind;
  final int minutes;
  final DateTime at;

  const ActivityEntry({
    required this.id,
    required this.kind,
    required this.minutes,
    required this.at,
  });

  /// A rough burn for the session. Deliberately not personalised by weight:
  /// this is a sense of scale, not a measurement, and dressing it up with a
  /// body-mass formula would only make the guess look authoritative.
  int get approxKcal => (minutes * 4 * kind.intensity).round();

  String get durationLabel {
    if (minutes < 60) return '$minutes';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h $m';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'minutes': minutes,
        'at': at.toIso8601String(),
      };

  factory ActivityEntry.fromJson(Map<String, dynamic> j) => ActivityEntry(
        id: j['id'] as String? ?? '',
        kind: ActivityKind.fromName(j['kind'] as String? ?? 'other'),
        minutes: (j['minutes'] as num?)?.toInt() ?? 0,
        at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime(2000),
      );
}

/// Everything logged on the same calendar day as [now], newest first.
List<ActivityEntry> activitiesOn(List<ActivityEntry> all, DateTime now) {
  bool sameDay(DateTime a) =>
      a.year == now.year && a.month == now.month && a.day == now.day;
  final today = all.where((e) => sameDay(e.at)).toList()
    ..sort((a, b) => b.at.compareTo(a.at));
  return today;
}

int totalMinutes(List<ActivityEntry> entries) =>
    entries.fold(0, (sum, e) => sum + e.minutes);

import 'package:equatable/equatable.dart';

/// A daily mood check-in: a 1–5 rating, the activities that filled the day, and
/// an optional note. One entry per day (upsert by date).
class MoodEntry extends Equatable {
  final DateTime date;
  final int mood; // 1 (awful) … 5 (great)
  final List<String> activities; // activity ids
  final String note;

  const MoodEntry({
    required this.date,
    required this.mood,
    this.activities = const [],
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'mood': mood,
        'activities': activities,
        'note': note,
      };

  factory MoodEntry.fromJson(Map<String, dynamic> j) => MoodEntry(
        date: DateTime.parse(j['date'] as String),
        mood: (j['mood'] as num?)?.toInt() ?? 3,
        activities: [for (final a in (j['activities'] as List? ?? [])) '$a'],
        note: (j['note'] as String?) ?? '',
      );

  @override
  List<Object?> get props => [date, mood, activities, note];
}

/// The five mood faces (index 0..4 → mood 1..5).
const moodFaces = ['😢', '😕', '😐', '🙂', '😄'];
String moodFace(int mood) => moodFaces[(mood - 1).clamp(0, 4)];

/// One taggable activity.
class MoodActivity {
  final String id;
  final String emoji;
  final String labelKey;
  const MoodActivity(this.id, this.emoji, this.labelKey);
}

class MoodActivities {
  const MoodActivities._();
  static const all = <MoodActivity>[
    MoodActivity('work', '💼', 'mood.act.work'),
    MoodActivity('study', '📖', 'mood.act.study'),
    MoodActivity('sport', '🏋️', 'mood.act.sport'),
    MoodActivity('friends', '🧑‍🤝‍🧑', 'mood.act.friends'),
    MoodActivity('family', '👨‍👩‍👧', 'mood.act.family'),
    MoodActivity('rest', '😴', 'mood.act.rest'),
    MoodActivity('outdoors', '🌳', 'mood.act.outdoors'),
    MoodActivity('food', '🍽️', 'mood.act.food'),
    MoodActivity('reading', '📚', 'mood.act.reading'),
    MoodActivity('hobby', '🎨', 'mood.act.hobby'),
    MoodActivity('travel', '✈️', 'mood.act.travel'),
    MoodActivity('health', '🏥', 'mood.act.health'),
  ];

  static MoodActivity? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}

/// How an activity relates to mood: average mood on days it happened vs the
/// overall average.
class MoodCorrelation extends Equatable {
  final String activityId;
  final double delta; // + = tends to lift mood
  final int count;
  const MoodCorrelation(this.activityId, this.delta, this.count);

  @override
  List<Object?> get props => [activityId, delta, count];
}

class MoodSummary extends Equatable {
  final int entries;
  final double average;
  final double last30;
  final List<MoodCorrelation> correlations; // strongest first (by |delta|)

  const MoodSummary({
    required this.entries,
    required this.average,
    required this.last30,
    required this.correlations,
  });

  @override
  List<Object?> get props => [entries, average, last30, correlations];
}

/// Pure analysis of a mood log.
class MoodAnalyzer {
  const MoodAnalyzer();

  MoodSummary? summarize(List<MoodEntry> log, DateTime now) {
    if (log.isEmpty) return null;
    final avg = log.map((e) => e.mood).reduce((a, b) => a + b) / log.length;

    final since = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 29));
    final recent = log.where((e) => !e.date.isBefore(since)).toList();
    final last30 = recent.isEmpty
        ? avg
        : recent.map((e) => e.mood).reduce((a, b) => a + b) / recent.length;

    // Correlations: activities appearing on ≥3 days.
    final sums = <String, int>{};
    final counts = <String, int>{};
    for (final e in log) {
      for (final a in e.activities) {
        sums[a] = (sums[a] ?? 0) + e.mood;
        counts[a] = (counts[a] ?? 0) + 1;
      }
    }
    final correlations = <MoodCorrelation>[];
    counts.forEach((id, n) {
      if (n < 3) return;
      correlations.add(MoodCorrelation(id, sums[id]! / n - avg, n));
    });
    correlations.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));

    return MoodSummary(
      entries: log.length,
      average: avg,
      last30: last30,
      correlations: correlations,
    );
  }
}

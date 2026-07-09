import 'package:equatable/equatable.dart';

/// The men's analog to cycle tracking: a daily "vitality" check-in. Men have no
/// monthly hormonal cycle to predict, so instead we track the levers that
/// actually move day-to-day wellbeing and surface the rhythm + trend.
class VitalityCheckin extends Equatable {
  final DateTime date;
  final int energy; // 1..5
  final int mood; // 1..5
  final int sleep; // 1..5 (quality)
  final int stress; // 1..5 (higher = worse)
  final int libido; // 1..5
  final bool trained;

  const VitalityCheckin({
    required this.date,
    this.energy = 3,
    this.mood = 3,
    this.sleep = 3,
    this.stress = 3,
    this.libido = 3,
    this.trained = false,
  });

  /// 0–100 wellbeing score: mean of the positive levers plus the inverted
  /// stress, with a small bonus for having trained.
  int get score {
    final positives = energy + mood + sleep + libido + (6 - stress); // 5..25
    final base = (positives - 5) / 20 * 100; // 0..100
    final withTraining = base + (trained ? 4 : 0);
    return withTraining.clamp(0, 100).round();
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'energy': energy,
        'mood': mood,
        'sleep': sleep,
        'stress': stress,
        'libido': libido,
        'trained': trained,
      };

  factory VitalityCheckin.fromJson(Map<String, dynamic> j) => VitalityCheckin(
        date: DateTime.parse(j['date'] as String),
        energy: (j['energy'] as num?)?.toInt() ?? 3,
        mood: (j['mood'] as num?)?.toInt() ?? 3,
        sleep: (j['sleep'] as num?)?.toInt() ?? 3,
        stress: (j['stress'] as num?)?.toInt() ?? 3,
        libido: (j['libido'] as num?)?.toInt() ?? 3,
        trained: (j['trained'] as bool?) ?? false,
      );

  @override
  List<Object?> get props =>
      [date, energy, mood, sleep, stress, libido, trained];
}

enum VitalityTrend {
  rising('📈', 'vitality.trend.rising'),
  steady('➡️', 'vitality.trend.steady'),
  falling('📉', 'vitality.trend.falling');

  const VitalityTrend(this.emoji, this.labelKey);
  final String emoji;
  final String labelKey;
}

/// A read on the last stretch of check-ins.
class VitalitySummary extends Equatable {
  final int latestScore;
  final int weekAverage;
  final VitalityTrend trend;
  final int streakDays; // consecutive days with a check-in ending today/yesterday
  final String phaseKey; // peak / good / recovery / low
  final String tipKey;

  const VitalitySummary({
    required this.latestScore,
    required this.weekAverage,
    required this.trend,
    required this.streakDays,
    required this.phaseKey,
    required this.tipKey,
  });

  @override
  List<Object?> get props =>
      [latestScore, weekAverage, trend, streakDays, phaseKey, tipKey];
}

/// Pure analysis of a check-in history (any order); returns null if empty.
class VitalityAnalyzer {
  const VitalityAnalyzer();

  VitalitySummary? summarize(List<VitalityCheckin> log, DateTime now) {
    if (log.isEmpty) return null;
    final sorted = [...log]..sort((a, b) => a.date.compareTo(b.date));
    final latest = sorted.last;

    final weekAgo = _dateOnly(now).subtract(const Duration(days: 6));
    final week = sorted.where((c) => !_dateOnly(c.date).isBefore(weekAgo));
    final weekAvg = week.isEmpty
        ? latest.score
        : (week.map((c) => c.score).reduce((a, b) => a + b) / week.length)
            .round();

    final trend = _trend(sorted);
    final streak = _streak(sorted, now);
    final phaseKey = _phaseKey(latest.score);

    return VitalitySummary(
      latestScore: latest.score,
      weekAverage: weekAvg,
      trend: trend,
      streakDays: streak,
      phaseKey: phaseKey,
      tipKey: _tipFor(latest),
    );
  }

  VitalityTrend _trend(List<VitalityCheckin> sorted) {
    if (sorted.length < 4) return VitalityTrend.steady;
    final recent = sorted.sublist(sorted.length - 3);
    final prior = sorted.sublist(
        (sorted.length - 6).clamp(0, sorted.length), sorted.length - 3);
    if (prior.isEmpty) return VitalityTrend.steady;
    final r = recent.map((c) => c.score).reduce((a, b) => a + b) / recent.length;
    final p = prior.map((c) => c.score).reduce((a, b) => a + b) / prior.length;
    if (r - p >= 6) return VitalityTrend.rising;
    if (p - r >= 6) return VitalityTrend.falling;
    return VitalityTrend.steady;
  }

  int _streak(List<VitalityCheckin> sorted, DateTime now) {
    final days = {for (final c in sorted) _dateOnly(c.date)};
    var cursor = _dateOnly(now);
    // Allow the streak to be "current" if the last check-in was today or
    // yesterday.
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    var count = 0;
    while (days.contains(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  String _phaseKey(int score) {
    if (score >= 75) return 'vitality.phase.peak';
    if (score >= 55) return 'vitality.phase.good';
    if (score >= 35) return 'vitality.phase.recovery';
    return 'vitality.phase.low';
  }

  /// Coaches the single weakest lever.
  String _tipFor(VitalityCheckin c) {
    final weakest = <String, int>{
      'vitality.coach.sleep': c.sleep,
      'vitality.coach.stress': 6 - c.stress,
      'vitality.coach.energy': c.energy,
      'vitality.coach.mood': c.mood,
    };
    var worstKey = 'vitality.coach.sleep';
    var worstVal = 6;
    weakest.forEach((k, v) {
      if (v < worstVal) {
        worstVal = v;
        worstKey = k;
      }
    });
    if (worstVal >= 4) return 'vitality.coach.keepUp';
    return worstKey;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

import 'package:equatable/equatable.dart';

/// Daily health metrics. Goals live in [HealthGoals]; the derived score lives in
/// `HealthScoreService`.
class HealthDay extends Equatable {
  final DateTime date;
  final int steps;
  final int waterGlasses;
  final double sleepHours;
  final double? weightKg;

  /// Perceived stress, 0 = not logged, 1 (calm) … 5 (very stressed).
  final int stress;

  /// Resting heart rate in bpm (from a device), null if unknown.
  final int? heartRate;

  /// Headphone listening time today, in minutes (§14 headphones module).
  final int listeningMinutes;

  const HealthDay({
    required this.date,
    this.steps = 0,
    this.waterGlasses = 0,
    this.sleepHours = 0,
    this.weightKg,
    this.stress = 0,
    this.heartRate,
    this.listeningMinutes = 0,
  });

  HealthDay copyWith({
    int? steps,
    int? waterGlasses,
    double? sleepHours,
    double? weightKg,
    int? stress,
    int? heartRate,
    int? listeningMinutes,
  }) =>
      HealthDay(
        date: date,
        steps: steps ?? this.steps,
        waterGlasses: waterGlasses ?? this.waterGlasses,
        sleepHours: sleepHours ?? this.sleepHours,
        weightKg: weightKg ?? this.weightKg,
        stress: stress ?? this.stress,
        heartRate: heartRate ?? this.heartRate,
        listeningMinutes: listeningMinutes ?? this.listeningMinutes,
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'steps': steps,
        'waterGlasses': waterGlasses,
        'sleepHours': sleepHours,
        'weightKg': weightKg,
        'stress': stress,
        'heartRate': heartRate,
        'listeningMinutes': listeningMinutes,
      };

  factory HealthDay.fromJson(Map<String, dynamic> json) => HealthDay(
        date: DateTime.parse(json['date'] as String),
        steps: (json['steps'] as int?) ?? 0,
        waterGlasses: (json['waterGlasses'] as int?) ?? 0,
        sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 0,
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        stress: (json['stress'] as int?) ?? 0,
        heartRate: json['heartRate'] as int?,
        listeningMinutes: (json['listeningMinutes'] as int?) ?? 0,
      );

  @override
  List<Object?> get props => [
        date,
        steps,
        waterGlasses,
        sleepHours,
        weightKg,
        stress,
        heartRate,
        listeningMinutes,
      ];
}

/// Daily targets used for progress rings and the health pillar of Life Score.
class HealthGoals {
  const HealthGoals._();
  static const steps = 10000;
  static const waterGlasses = 8;
  static const sleepHours = 8.0;
}

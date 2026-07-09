import 'package:equatable/equatable.dart';

/// A frozen summary of one calendar month across every pillar — the unit of the
/// long-term "life history" archive. Stored once a month completes so the user
/// can look back a year, five years, etc.
class MonthlySnapshot extends Equatable {
  /// year * 100 + month, e.g. 202607.
  final int ym;
  final int spentMinor;
  final int incomeMinor;
  final String? topCategoryId;
  final double? avgMood; // 1..5, null if none logged
  final int avgSteps;
  final double avgWater;
  final double avgSleep;
  final double? weightKg;

  const MonthlySnapshot({
    required this.ym,
    this.spentMinor = 0,
    this.incomeMinor = 0,
    this.topCategoryId,
    this.avgMood,
    this.avgSteps = 0,
    this.avgWater = 0,
    this.avgSleep = 0,
    this.weightKg,
  });

  int get year => ym ~/ 100;
  int get month => ym % 100;
  int get netMinor => incomeMinor - spentMinor;

  bool get hasData =>
      spentMinor > 0 ||
      incomeMinor > 0 ||
      avgMood != null ||
      avgSteps > 0 ||
      weightKg != null;

  Map<String, dynamic> toJson() => {
        'ym': ym,
        'spentMinor': spentMinor,
        'incomeMinor': incomeMinor,
        'topCategoryId': topCategoryId,
        'avgMood': avgMood,
        'avgSteps': avgSteps,
        'avgWater': avgWater,
        'avgSleep': avgSleep,
        'weightKg': weightKg,
      };

  factory MonthlySnapshot.fromJson(Map<String, dynamic> j) => MonthlySnapshot(
        ym: (j['ym'] as num).toInt(),
        spentMinor: (j['spentMinor'] as num?)?.toInt() ?? 0,
        incomeMinor: (j['incomeMinor'] as num?)?.toInt() ?? 0,
        topCategoryId: j['topCategoryId'] as String?,
        avgMood: (j['avgMood'] as num?)?.toDouble(),
        avgSteps: (j['avgSteps'] as num?)?.toInt() ?? 0,
        avgWater: (j['avgWater'] as num?)?.toDouble() ?? 0,
        avgSleep: (j['avgSleep'] as num?)?.toDouble() ?? 0,
        weightKg: (j['weightKg'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [
        ym, spentMinor, incomeMinor, topCategoryId, avgMood, avgSteps,
        avgWater, avgSleep, weightKg, //
      ];
}

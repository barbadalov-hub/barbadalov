import 'package:equatable/equatable.dart';

/// What the user uses for their period — chosen in the questionnaire so the
/// pre-period reminder can name the right thing to pack.
enum ProtectionType {
  pads('🩹', 'protect.pads'),
  tampons('🧴', 'protect.tampons'),
  cup('🌙', 'protect.cup'),
  underwear('🩲', 'protect.underwear');

  const ProtectionType(this.emoji, this.labelKey);
  final String emoji;
  final String labelKey;

  static ProtectionType fromName(String name) => values.firstWhere(
        (p) => p.name == name,
        orElse: () => ProtectionType.pads,
      );
}

/// The four menstrual-cycle phases. Labels/tips are i18n keys resolved in the
/// UI so the tracker speaks the user's language.
enum CyclePhase {
  menstrual('🩸', 'cycle.phase.menstrual', 'cycle.tip.menstrual'),
  follicular('🌱', 'cycle.phase.follicular', 'cycle.tip.follicular'),
  ovulation('⭐', 'cycle.phase.ovulation', 'cycle.tip.ovulation'),
  luteal('🌙', 'cycle.phase.luteal', 'cycle.tip.luteal');

  const CyclePhase(this.emoji, this.labelKey, this.tipKey);
  final String emoji;
  final String labelKey;
  final String tipKey;
}

/// The user's cycle setup, gathered by the questionnaire. Dates are day-precise.
class CycleData extends Equatable {
  final DateTime lastPeriodStart;
  final int cycleLength; // days between period starts (typ. 21–35)
  final int periodLength; // bleeding days (typ. 3–7)
  final ProtectionType protection; // what to remind the user to pack

  const CycleData({
    required this.lastPeriodStart,
    this.cycleLength = 28,
    this.periodLength = 5,
    this.protection = ProtectionType.pads,
  });

  CycleData copyWith({
    DateTime? lastPeriodStart,
    int? cycleLength,
    int? periodLength,
    ProtectionType? protection,
  }) =>
      CycleData(
        lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
        cycleLength: cycleLength ?? this.cycleLength,
        periodLength: periodLength ?? this.periodLength,
        protection: protection ?? this.protection,
      );

  Map<String, dynamic> toJson() => {
        'lastPeriodStart': lastPeriodStart.toIso8601String(),
        'cycleLength': cycleLength,
        'periodLength': periodLength,
        'protection': protection.name,
      };

  factory CycleData.fromJson(Map<String, dynamic> j) => CycleData(
        lastPeriodStart: DateTime.parse(j['lastPeriodStart'] as String),
        cycleLength: (j['cycleLength'] as num?)?.toInt() ?? 28,
        periodLength: (j['periodLength'] as num?)?.toInt() ?? 5,
        protection: ProtectionType.fromName(j['protection'] as String? ?? 'pads'),
      );

  @override
  List<Object?> get props =>
      [lastPeriodStart, cycleLength, periodLength, protection];
}

/// The computed state of the current cycle for a given day.
class CyclePrediction extends Equatable {
  final int cycleDay; // 1-based day within the current cycle
  final CyclePhase phase;
  final DateTime nextPeriodStart;
  final int daysUntilNextPeriod;
  final DateTime ovulationDate;
  final DateTime fertileStart;
  final DateTime fertileEnd;
  final bool isFertile;

  const CyclePrediction({
    required this.cycleDay,
    required this.phase,
    required this.nextPeriodStart,
    required this.daysUntilNextPeriod,
    required this.ovulationDate,
    required this.fertileStart,
    required this.fertileEnd,
    required this.isFertile,
  });

  @override
  List<Object?> get props => [
        cycleDay, phase, nextPeriodStart, daysUntilNextPeriod, ovulationDate,
        fertileStart, fertileEnd, isFertile, //
      ];
}

/// Pure cycle math (calendar method). Ovulation is estimated 14 days before the
/// next period; the fertile window spans the 5 days before ovulation plus the
/// day after. This is a prediction aid, not contraception or medical advice.
class CyclePredictor {
  const CyclePredictor();

  CyclePrediction predict(CycleData data, DateTime now) {
    final today = _dateOnly(now);
    final start = _dateOnly(data.lastPeriodStart);
    final len = data.cycleLength.clamp(15, 60);

    // Which cycle are we in, and when did it start?
    final daysSince = today.difference(start).inDays;
    final cyclesElapsed = daysSince >= 0 ? daysSince ~/ len : 0;
    final currentStart = start.add(Duration(days: cyclesElapsed * len));
    final nextStart = currentStart.add(Duration(days: len));

    final cycleDay = today.difference(currentStart).inDays + 1;
    final daysUntilNext = nextStart.difference(today).inDays;

    // Ovulation ~14 days before the next period.
    final ovulation = nextStart.subtract(const Duration(days: 14));
    final fertileStart = ovulation.subtract(const Duration(days: 5));
    final fertileEnd = ovulation.add(const Duration(days: 1));

    // Ovulation date is currentStart + (len - 14), i.e. cycle-day (len - 13).
    final ovulationDayNum = len - 13;
    final phase = _phaseFor(cycleDay, data.periodLength, ovulationDayNum);
    final isFertile = !today.isBefore(fertileStart) && !today.isAfter(fertileEnd);

    return CyclePrediction(
      cycleDay: cycleDay,
      phase: phase,
      nextPeriodStart: nextStart,
      daysUntilNextPeriod: daysUntilNext,
      ovulationDate: ovulation,
      fertileStart: fertileStart,
      fertileEnd: fertileEnd,
      isFertile: isFertile,
    );
  }

  CyclePhase _phaseFor(int cycleDay, int periodLength, int ovulationDayNum) {
    final fertileStart = ovulationDayNum - 5;
    final fertileEnd = ovulationDayNum + 1;
    if (cycleDay <= periodLength) return CyclePhase.menstrual;
    if (cycleDay == ovulationDayNum) return CyclePhase.ovulation;
    if (cycleDay >= fertileStart && cycleDay <= fertileEnd) {
      return CyclePhase.follicular;
    }
    if (cycleDay < fertileStart) return CyclePhase.follicular;
    return CyclePhase.luteal;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

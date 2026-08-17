/// One recorded top-up. Kept separately from the goal because a goal only
/// stores a running total, and a total cannot tell you whether it took two
/// weeks or two years to get there.
class GoalContribution {
  final String goalId;
  final int minorUnits;
  final DateTime at;

  const GoalContribution({
    required this.goalId,
    required this.minorUnits,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
        'goalId': goalId,
        'minor': minorUnits,
        'at': at.toIso8601String(),
      };

  factory GoalContribution.fromJson(Map<String, dynamic> j) =>
      GoalContribution(
        goalId: j['goalId'] as String? ?? '',
        minorUnits: (j['minor'] as num?)?.toInt() ?? 0,
        at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime(2000),
      );
}

/// What the record of top-ups says about when a goal actually arrives.
class PaceEstimate {
  /// Average put aside per month, from real top-ups.
  final int perMonthMinor;

  /// Months still needed at that rate.
  final int monthsRemaining;
  final DateTime arrivesOn;

  /// How many top-ups the estimate rests on. Shown, because a projection built
  /// on two payments deserves to be read with a raised eyebrow.
  final int basedOn;

  const PaceEstimate({
    required this.perMonthMinor,
    required this.monthsRemaining,
    required this.arrivesOn,
    required this.basedOn,
  });
}

/// Turns a history of top-ups into a date.
///
/// The existing forecast answers "when would this arrive if I put my whole
/// spare budget into it" — a statement about intentions. This one answers
/// "when will it arrive if I carry on exactly as I have been", which is a
/// statement about behaviour, and usually the more useful of the two.
class GoalPace {
  /// Below this there is no pace, only a couple of payments. Two points can be
  /// drawn through any line you like; pretending that is a forecast would be
  /// worse than admitting there is not one yet.
  static const minContributions = 2;

  /// A window long enough to be a habit and short enough to reflect the
  /// present. A burst of saving two years ago should not still be flattering
  /// today's estimate.
  static const windowDays = 180;

  static PaceEstimate? estimate({
    required List<GoalContribution> contributions,
    required int remainingMinor,
    required DateTime now,
  }) {
    if (remainingMinor <= 0) return null;

    final cutoff = now.subtract(const Duration(days: windowDays));
    final recent = contributions
        .where((c) => c.minorUnits > 0 && c.at.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));

    if (recent.length < minContributions) return null;

    final total = recent.fold(0, (sum, c) => sum + c.minorUnits);

    // Measured from the first top-up to *now*, not to the last one. Stopping
    // three months ago is part of the pace: measuring only the active stretch
    // would report the rate of someone who has since gone quiet.
    final spanDays = now.difference(recent.first.at).inDays;
    // A day of history cannot imply a monthly rate; hold the floor at a week
    // so a flurry in one afternoon does not project to a fortune per month.
    final days = spanDays < 7 ? 7 : spanDays;

    final perDay = total / days;
    final perMonth = (perDay * 30).round();
    if (perMonth <= 0) return null;

    final months = (remainingMinor / perMonth).ceil();
    return PaceEstimate(
      perMonthMinor: perMonth,
      monthsRemaining: months,
      arrivesOn: _addMonths(now, months),
      basedOn: recent.length,
    );
  }

  static DateTime _addMonths(DateTime from, int months) {
    final target = from.month + months;
    final year = from.year + (target - 1) ~/ 12;
    final month = (target - 1) % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, from.day < lastDay ? from.day : lastDay);
  }
}

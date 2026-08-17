/// A goal offered to someone who has none yet.
class GoalStarter {
  final String emoji;
  final String titleKey;

  /// Suggested target in minor units.
  final int targetMinor;

  /// True when [targetMinor] was worked out from the user's own spending
  /// rather than picked as a round number — the card says so, because a
  /// figure presented as personal when it is not is worse than no figure.
  final bool personal;

  const GoalStarter({
    required this.emoji,
    required this.titleKey,
    required this.targetMinor,
    this.personal = false,
  });
}

/// The four goals almost everyone eventually names, offered up front.
///
/// An empty Goals room is the worst first impression in the app: one sentence,
/// one tool tile and a screen of nothing. "Name a goal" is not help — a blank
/// field is exactly the moment people leave.
class GoalStarters {
  /// [monthlyExpensesMinor] is what the user actually spends in a month, when
  /// known. Only the emergency fund uses it; the rest are round numbers and
  /// admit it.
  static List<GoalStarter> forUser({required int monthlyExpensesMinor}) {
    // Three months of real spending is the standard advice and the one figure
    // here that can be genuinely personal. Rounded up to a whole hundred so it
    // reads as a goal rather than as a calculation.
    final known = monthlyExpensesMinor > 0;
    final cushion = known
        ? ((monthlyExpensesMinor * 3) / 10000).ceil() * 10000
        : 300000;

    return [
      GoalStarter(
        emoji: '🛟',
        titleKey: 'starter.cushion',
        targetMinor: cushion,
        personal: known,
      ),
      const GoalStarter(
          emoji: '🏖', titleKey: 'starter.trip', targetMinor: 100000),
      const GoalStarter(
          emoji: '💻', titleKey: 'starter.gear', targetMinor: 150000),
      const GoalStarter(
          emoji: '🏠', titleKey: 'starter.home', targetMinor: 1000000),
    ];
  }
}

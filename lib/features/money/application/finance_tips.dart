/// A small curated library of evergreen personal-finance tips (i18n keys). One
/// is surfaced per day on the Money screen — steady, non-nagging education that
/// complements the live [SpendingAnalyzer] recommendations.
class FinanceTips {
  const FinanceTips._();

  static const keys = <String>[
    'ftip.payYourself',
    'ftip.emergency',
    'ftip.trackAll',
    'ftip.rule24h',
    'ftip.subscriptions',
    'ftip.needsWants',
    'ftip.autoSave',
    'ftip.avoidDebt',
    'ftip.invest',
    'ftip.reviewWeekly',
    'ftip.bulk',
    'ftip.goalWhy',
  ];

  /// Deterministic tip for a given day, so it stays stable within a day and
  /// rotates across the list over time.
  static String ofDay(DateTime now) {
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return keys[dayOfYear % keys.length];
  }
}

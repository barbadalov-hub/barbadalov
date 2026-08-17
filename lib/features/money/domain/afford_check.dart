/// How a purchase sits against what is actually left.
enum AffordVerdict {
  /// Barely dents the month.
  easy,

  /// Fits, but you will feel it.
  tight,

  /// More than there is.
  no,
}

class AffordAnswer {
  final AffordVerdict verdict;
  final String reasonKey;
  final Map<String, Object> params;

  /// Whole days of the remaining allowance this would eat, rounded up. The
  /// honest unit: money left means nothing without knowing how long it has to
  /// last, and "four of your twelve remaining days" is a fact rather than an
  /// opinion about whether you deserve it.
  final int daysCost;

  const AffordAnswer({
    required this.verdict,
    required this.reasonKey,
    required this.daysCost,
    this.params = const {},
  });
}

/// Answers "can I afford this?" without moralising.
///
/// Every other number in the room describes what already happened. This is the
/// only one that answers a question about a decision that has not been made
/// yet, which is what people actually stand in a shop wondering.
class AffordCheck {
  /// [freeLeftMinor] is income minus reserve minus what is already spent —
  /// the money genuinely available for the rest of the month.
  static AffordAnswer? ask({
    required int amountMinor,
    required int freeLeftMinor,
    required int daysLeftInMonth,
  }) {
    // Nothing typed yet is not a question, so it deserves no verdict.
    if (amountMinor <= 0) return null;

    final days = daysLeftInMonth < 1 ? 1 : daysLeftInMonth;

    if (freeLeftMinor <= 0) {
      return const AffordAnswer(
        verdict: AffordVerdict.no,
        reasonKey: 'afford.nothingLeft',
        daysCost: 0,
      );
    }

    if (amountMinor > freeLeftMinor) {
      return AffordAnswer(
        verdict: AffordVerdict.no,
        reasonKey: 'afford.over',
        daysCost: days,
        params: {'over': amountMinor - freeLeftMinor},
      );
    }

    // Ceiling, not rounding: spending most of a day's allowance costs you that
    // day, and rounding 0.6 down to zero would flatter the purchase.
    final perDay = freeLeftMinor / days;
    final cost = (amountMinor / perDay).ceil();

    // Half of what is left is the line where a purchase stops being a purchase
    // and starts being the rest of your month.
    final heavy = amountMinor * 2 >= freeLeftMinor;
    return AffordAnswer(
      verdict: heavy ? AffordVerdict.tight : AffordVerdict.easy,
      reasonKey: heavy ? 'afford.tight' : 'afford.easy',
      daysCost: cost,
      params: {
        'days': cost,
        'left': freeLeftMinor - amountMinor,
      },
    );
  }

  /// Days remaining in [now]'s month, counting today.
  static int daysLeftInMonth(DateTime now) {
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return lastDay - now.day + 1;
  }
}

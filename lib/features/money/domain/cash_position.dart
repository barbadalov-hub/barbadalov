import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/recurring_rule.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/shared/models/money.dart';

/// A statement from the user: "on this date I had exactly this much".
///
/// Everything the app knows about the past is folded into this one number, the
/// way a bank reconciliation works. Re-stating it later is not a correction of
/// history — it is a new starting point, which is what makes the figure
/// self-healing: cash spent without logging it drifts the balance, and one
/// re-statement wipes the drift out.
class BalanceAnchor {
  final Money amount;

  /// The moment the amount was true. Movements recorded *after* it move the
  /// balance; movements before it are already inside [amount].
  final DateTime on;

  const BalanceAnchor({required this.amount, required this.on});

  Map<String, dynamic> toJson() => {
        'minorUnits': amount.minorUnits,
        'currency': amount.currency,
        'on': on.toIso8601String(),
      };

  static BalanceAnchor? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final on = DateTime.tryParse((j['on'] as String?) ?? '');
    final minor = (j['minorUnits'] as num?)?.toInt();
    if (on == null || minor == null) return null;
    return BalanceAnchor(
      amount: Money(minor, currency: (j['currency'] as String?) ?? 'USD'),
      on: on,
    );
  }
}

/// What the user actually has, and how much of it is already promised.
///
/// This exists because a calendar month is not how money works. Income arrives
/// on the 5th, not on the 1st; what is left on the 31st is still there on the
/// 1st. A figure derived from "this month's income minus this month's
/// expenses" resets to nothing every month and reports someone who installed
/// the app after payday as having nothing at all.
class CashPosition {
  /// Whether the user has ever said what they have. Without it the app does
  /// not know, and must not imply that it does.
  final bool anchored;

  /// Real money right now: the stated balance plus everything recorded since.
  final Money onHand;

  /// Known charges falling due before the next income arrives.
  final Money committed;

  /// Savings carved out of this month's income.
  final Money reserve;

  /// What is genuinely free to spend. **Negative when the money on hand does
  /// not cover what is already promised** — this is the single most important
  /// thing a person can be told, and clamping it to zero hides it.
  final Money free;

  /// Even split of [free] across [daysCovered]. Zero when [free] is negative,
  /// because in that case nothing is safe to spend; the size of the hole is
  /// reported by [shortfall] rather than smuggled into a daily figure.
  final Money perDay;

  /// How far the money has to stretch: days until the next income lands,
  /// counting today, or the rest of the month when no income is scheduled.
  final int daysCovered;

  /// When money is next expected, if a recurring income says so.
  final DateTime? nextIncomeOn;

  const CashPosition({
    required this.anchored,
    required this.onHand,
    required this.committed,
    required this.reserve,
    required this.free,
    required this.perDay,
    required this.daysCovered,
    this.nextIncomeOn,
  });

  factory CashPosition.unknown({String currency = 'USD'}) => CashPosition(
        anchored: false,
        onHand: Money.zero(currency: currency),
        committed: Money.zero(currency: currency),
        reserve: Money.zero(currency: currency),
        free: Money.zero(currency: currency),
        perDay: Money.zero(currency: currency),
        daysCovered: 0,
      );

  /// How far short the money falls, as a positive amount. Zero when it covers.
  Money get shortfall =>
      free.isNegative ? Money(-free.minorUnits, currency: free.currency)
                      : Money.zero(currency: free.currency);

  bool get isShort => free.isNegative;

  /// The one sentence worth leading with, as an i18n key.
  String get verdictKey {
    if (!anchored) return 'cash.unknown';
    if (isShort) return 'cash.short';
    if (committed.isPositive) return 'cash.afterBills';
    return 'cash.free';
  }
}

/// Turns a stated balance, the movements since, and the known bills into a
/// truthful picture of the money. Pure, so every judgement below is testable.
class CashPositionCalculator {
  const CashPositionCalculator();

  CashPosition build({
    BalanceAnchor? anchor,
    required List<Transaction> transactions,
    required DateTime now,
    List<RecurringRule> rules = const [],
    Money? reserve,
    String currency = 'USD',
  }) {
    if (anchor == null) return CashPosition.unknown(currency: currency);

    final today = DateTime(now.year, now.month, now.day);
    final cur = anchor.amount.currency;

    // Only what was recorded after the statement moves the balance. Anything
    // earlier is already inside the stated figure, and counting it twice would
    // make every reconciliation worse than no reconciliation at all.
    var minor = anchor.amount.minorUnits;
    for (final t in transactions) {
      if (t.date.isAfter(anchor.on)) minor += t.signedMinorUnits;
    }
    final onHand = Money(minor, currency: cur);

    final nextIncome = _nextIncomeDate(rules, today);
    final windowEnd = nextIncome ?? _nextMonthStart(today);
    final daysCovered = _daysBetween(today, windowEnd).clamp(1, 366).toInt();

    var committedMinor = 0;
    for (final r in rules) {
      if (!r.active || r.type != TransactionType.expense) continue;
      final due = _nextDue(r, today);
      if (!due.isAfter(windowEnd)) committedMinor += r.amountMinor;
    }
    final committed = Money(committedMinor, currency: cur);

    final res = reserve ?? Money.zero(currency: cur);
    final free = onHand - committed - res;
    final perDay = free.isNegative
        ? Money.zero(currency: cur)
        : Money(free.minorUnits ~/ daysCovered, currency: cur);

    return CashPosition(
      anchored: true,
      onHand: onHand,
      committed: committed,
      reserve: res,
      free: free,
      perDay: perDay,
      daysCovered: daysCovered,
      nextIncomeOn: nextIncome,
    );
  }

  /// Earliest date an active recurring income is expected, or null.
  DateTime? _nextIncomeDate(List<RecurringRule> rules, DateTime today) {
    DateTime? best;
    for (final r in rules) {
      if (!r.active || r.type != TransactionType.income) continue;
      final due = _nextDue(r, today);
      if (best == null || due.isBefore(best)) best = due;
    }
    return best;
  }

  /// When a rule is next expected to fire.
  ///
  /// A rule whose day has already passed without firing is ambiguous, and the
  /// two kinds resolve it in opposite directions — both toward the cautious
  /// answer, because the cost of the errors is not symmetric:
  ///
  /// * an **expense** is treated as due now. It is about to be materialised,
  ///   and pushing it a month out would flatter the balance at exactly the
  ///   moment the charge is about to land.
  /// * an **income** is treated as next month's. Money that was due and has
  ///   not arrived is money to not count on; assuming it lands today would
  ///   close the window at once and offer the whole balance as today's
  ///   allowance.
  DateTime _nextDue(RecurringRule r, DateTime today) {
    final nextMonth = DateTime(today.year, today.month + 1, r.dayOfMonth);
    if (r.lastRun == _monthKey(today)) return nextMonth;

    final thisMonth = DateTime(today.year, today.month, r.dayOfMonth);
    if (!thisMonth.isBefore(today)) return thisMonth;
    return r.type == TransactionType.expense ? today : nextMonth;
  }

  static String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  /// The fallback end of the window when no income is scheduled.
  ///
  /// The first of next month, not the last of this one: money on the 18th has
  /// to survive *through* the 31st, and stopping the count a day early divides
  /// it into a slightly larger daily allowance than actually exists.
  static DateTime _nextMonthStart(DateTime d) =>
      DateTime(d.year, d.month + 1, 1);

  /// Whole days from [a] to [b], counting today. Date-only, so daylight saving
  /// cannot shave a day off.
  static int _daysBetween(DateTime a, DateTime b) {
    final from = DateTime(a.year, a.month, a.day);
    final to = DateTime(b.year, b.month, b.day);
    return to.difference(from).inDays;
  }
}

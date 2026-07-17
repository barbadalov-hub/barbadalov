import 'package:lifeos/features/money/domain/entities/transaction.dart';

/// This-month vs last-month spending, compared **over the same elapsed days**
/// (1..today) so an early-in-the-month partial total isn't measured against a
/// full previous month. Carries the category that moved the most. Pure —
/// unit-tested.
class MonthComparison {
  final int thisSpent;
  final int lastSpent;
  final String? topMoverCategory;
  final int topMoverDelta; // signed (this − last)
  const MonthComparison({
    required this.thisSpent,
    required this.lastSpent,
    this.topMoverCategory,
    this.topMoverDelta = 0,
  });

  bool get hasLast => lastSpent > 0;
  int get delta => thisSpent - lastSpent;
  int? get pctChange =>
      lastSpent == 0 ? null : (delta * 100 / lastSpent).round();

  /// Builds the comparison from all [transactions] as of [now]. Only expenses
  /// dated on or before today's day-of-month count on both sides, making the
  /// two periods like-for-like.
  static MonthComparison compute({
    required List<Transaction> transactions,
    required DateTime now,
  }) {
    final lastMonth = DateTime(now.year, now.month - 1);
    final cutoffDay = now.day; // compare the same number of days each side

    var thisSpent = 0;
    var lastSpent = 0;
    final thisCat = <String, int>{};
    final lastCat = <String, int>{};
    for (final t in transactions) {
      if (!t.isExpense || t.date.day > cutoffDay) continue;
      if (t.date.year == now.year && t.date.month == now.month) {
        thisSpent += t.amount.minorUnits;
        thisCat[t.categoryId] =
            (thisCat[t.categoryId] ?? 0) + t.amount.minorUnits;
      } else if (t.date.year == lastMonth.year &&
          t.date.month == lastMonth.month) {
        lastSpent += t.amount.minorUnits;
        lastCat[t.categoryId] =
            (lastCat[t.categoryId] ?? 0) + t.amount.minorUnits;
      }
    }

    String? mover;
    var moverDelta = 0;
    for (final cat in {...thisCat.keys, ...lastCat.keys}) {
      final d = (thisCat[cat] ?? 0) - (lastCat[cat] ?? 0);
      if (d.abs() > moverDelta.abs()) {
        moverDelta = d;
        mover = cat;
      }
    }

    return MonthComparison(
      thisSpent: thisSpent,
      lastSpent: lastSpent,
      topMoverCategory: mover,
      topMoverDelta: moverDelta,
    );
  }
}

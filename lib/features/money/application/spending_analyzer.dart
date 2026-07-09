import 'package:equatable/equatable.dart';
import 'package:lifeos/features/goals/domain/entities/goal.dart';
import 'package:lifeos/features/money/domain/entities/budget.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/shared/models/money.dart';

/// One "smart finance" observation (i18n key + params, like AI insights).
class FinanceInsight extends Equatable {
  final String emoji;
  final String titleKey;
  final String msgKey;
  final Map<String, Object> params;
  final bool positive;

  const FinanceInsight({
    required this.emoji,
    required this.titleKey,
    required this.msgKey,
    this.params = const {},
    this.positive = false,
  });

  @override
  List<Object?> get props => [emoji, titleKey, msgKey, params, positive];
}

/// The "smart finance" brain (rule set distilled from open-source finance
/// managers à la Firefly III / Ivy Wallet): reads this month's transactions and
/// answers, in plain language — how fast you're spending vs the plan, where
/// you'll land at month-end, which category to squeeze, and what the current
/// pace does to your top goal.
class SpendingAnalyzer {
  const SpendingAnalyzer();

  /// Categories it makes sense to squeeze (discretionary first).
  static const _cuttable = ['expense_fun', 'expense_food', 'expense_transport', 'expense_other'];

  /// Categories that count as "needs" vs "wants" for the 50/30/20 check.
  static const _wants = ['expense_fun', 'expense_other'];

  List<FinanceInsight> analyze({
    required Budget budget,
    required List<Transaction> monthTransactions,
    required List<Goal> goals,
    required DateTime now,
  }) {
    final insights = <FinanceInsight>[];
    if (budget.income.isZero) return insights;

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final daysLeft = daysInMonth - daysPassed;
    final currency = budget.income.currency;

    final spendable = budget.income.minorUnits - budget.reserve.minorUnits;
    final plannedDailyMinor = spendable ~/ daysInMonth;
    final actualDailyMinor =
        daysPassed == 0 ? 0 : budget.expenses.minorUnits ~/ daysPassed;
    final projectedMinor =
        budget.expenses.minorUnits + actualDailyMinor * daysLeft;

    // Spend grouped by category once, reused by several rules.
    final byCategory = <String, int>{};
    for (final t in monthTransactions) {
      if (t.isExpense) {
        byCategory[t.categoryId] =
            (byCategory[t.categoryId] ?? 0) + t.amount.minorUnits;
      }
    }

    Money m(int minor) => Money(minor, currency: currency);

    // 0. Daily allowance for the rest of the month — the single most actionable
    //    number: what you can spend per day and still stay within plan.
    if (spendable > 0 && daysLeft > 0) {
      final remaining =
          (spendable - budget.expenses.minorUnits).clamp(0, 1 << 62).toInt();
      final perDay = remaining ~/ daysLeft;
      insights.add(FinanceInsight(
        emoji: '📅',
        titleKey: 'smart.allowance.title',
        msgKey: 'smart.allowance.msg',
        params: {'perDay': m(perDay).format(), 'left': m(remaining).format()},
        positive: perDay > 0,
      ));
    }

    // 1. Spending pace vs plan.
    if (budget.expenses.isPositive) {
      if (actualDailyMinor > plannedDailyMinor * 1.05) {
        insights.add(FinanceInsight(
          emoji: '🚨',
          titleKey: 'smart.pace.title',
          msgKey: 'smart.pace.msg',
          params: {
            'actual': m(actualDailyMinor).format(),
            'planned': m(plannedDailyMinor).format(),
          },
        ));
      } else {
        insights.add(FinanceInsight(
          emoji: '✅',
          titleKey: 'smart.paceOk.title',
          msgKey: 'smart.paceOk.msg',
          params: {
            'save': m((plannedDailyMinor - actualDailyMinor)
                    .clamp(0, 1 << 62)
                    .toInt())
                .format(),
          },
          positive: true,
        ));
      }
    }

    // 2. Month-end projection.
    if (projectedMinor > spendable && spendable > 0) {
      insights.add(FinanceInsight(
        emoji: '📉',
        titleKey: 'smart.projection.title',
        msgKey: 'smart.projection.msg',
        params: {'over': m(projectedMinor - spendable).format()},
      ));
    }

    // 2b. Projected savings rate — praise good months, nudge weak ones.
    final projectedSaved = budget.income.minorUnits - projectedMinor;
    final savingsRate =
        (projectedSaved * 100 / budget.income.minorUnits).round();
    if (savingsRate >= 20) {
      insights.add(FinanceInsight(
        emoji: '🏆',
        titleKey: 'smart.savings.title',
        msgKey: 'smart.savingsGood.msg',
        params: {'rate': savingsRate},
        positive: true,
      ));
    } else if (savingsRate < 10 && budget.expenses.isPositive) {
      insights.add(FinanceInsight(
        emoji: '🪙',
        titleKey: 'smart.savings.title',
        msgKey: 'smart.savingsLow.msg',
        params: {'rate': savingsRate < 0 ? 0 : savingsRate},
      ));
    }

    // 2c. Biggest category share — where the money actually goes.
    if (budget.expenses.isPositive) {
      final top = byCategory.entries
          .reduce((a, b) => a.value >= b.value ? a : b);
      final pct = (top.value * 100 / budget.expenses.minorUnits).round();
      insights.add(FinanceInsight(
        emoji: '📊',
        titleKey: 'smart.top.title',
        msgKey: 'smart.top.msg',
        params: {
          'catId': 'cat.${top.key}',
          'amount': m(top.value).format(),
          'pct': pct,
        },
      ));
    }

    // 2d. 50/30/20 sanity: keep "wants" (fun + misc) under ~30% of income.
    final wantsMinor = _wants.fold(0, (s, id) => s + (byCategory[id] ?? 0));
    if (wantsMinor > 0 && budget.income.isPositive) {
      final wantsPct = (wantsMinor * 100 / budget.income.minorUnits).round();
      if (wantsPct > 30) {
        insights.add(FinanceInsight(
          emoji: '🍹',
          titleKey: 'smart.wants.title',
          msgKey: 'smart.wants.msg',
          params: {'pct': wantsPct, 'amount': m(wantsMinor).format()},
        ));
      }
    }

    // 3. Which category to squeeze: the biggest discretionary spender.
    String? cutId;
    var cutMinor = 0;
    for (final id in _cuttable) {
      final v = byCategory[id] ?? 0;
      if (v > cutMinor) {
        cutMinor = v;
        cutId = id;
      }
    }
    if (cutId != null &&
        budget.expenses.isPositive &&
        projectedMinor > spendable) {
      final pct = (cutMinor * 100 / budget.expenses.minorUnits).round();
      insights.add(FinanceInsight(
        emoji: '✂️',
        titleKey: 'smart.cut.title',
        msgKey: 'smart.cut.msg',
        params: {
          'catId': 'cat.$cutId',
          'amount': m(cutMinor).format(),
          'pct': pct,
        },
      ));
    }

    // 4. Impact of the current pace on the top goal: months to reach it if the
    //    month ends as planned (leftover = available) vs at the current pace
    //    (leftover = spendable − projected spend).
    final active = goals.where((g) => !g.isComplete).toList();
    if (active.isNotEmpty && actualDailyMinor > 0) {
      final goal = active.first;
      final planNet = budget.available.minorUnits;
      final projectedNet =
          (spendable - projectedMinor).clamp(0, 1 << 62).toInt();
      if (planNet > 0 && projectedNet < planNet) {
        final monthsPlan = (goal.remaining.minorUnits / planNet).ceil();
        final monthsProjected = projectedNet == 0
            ? monthsPlan + 99
            : (goal.remaining.minorUnits / projectedNet).ceil();
        final delay = monthsProjected - monthsPlan;
        if (delay > 0) {
          insights.add(FinanceInsight(
            emoji: '🎯',
            titleKey: 'smart.goal.title',
            msgKey: 'smart.goal.msg',
            params: {'title': goal.title, 'months': delay},
          ));
        }
      }
    }

    return insights;
  }
}

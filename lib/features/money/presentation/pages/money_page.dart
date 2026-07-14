import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/utils/download_file.dart';
import 'package:lifeos/features/money/application/transaction_csv.dart';
import 'package:lifeos/features/money/domain/entities/budget.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/features/money/presentation/pages/budget_limits_page.dart';
import 'package:lifeos/features/money/presentation/pages/category_rules_page.dart';
import 'package:lifeos/features/money/presentation/pages/csv_import_page.dart';
import 'package:lifeos/features/money/presentation/pages/receipt_page.dart';
import 'package:lifeos/features/money/presentation/pages/recurring_page.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/features/money/presentation/widgets/add_transaction_sheet.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';
import 'package:lifeos/shared/widgets/motion.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// MoneyOS home — the balance header plus the full transaction history. Adding a
/// transaction flows through the event pipeline and this list updates reactively.
class MoneyPage extends ConsumerWidget {
  const MoneyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);
    final budget = ref.watch(currentBudgetProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('nav.money')),
        actions: [
          IconButton(
            tooltip: context.tr('receipt.title'),
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ReceiptPage()),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'csv':
                  _exportCsv(context, ref);
                case 'limits':
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const BudgetLimitsPage()));
                case 'recurring':
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const RecurringPage()));
                case 'rules':
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const CategoryRulesPage()));
                case 'import':
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const CsvImportPage()));
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'limits',
                child: Text('🎯 ${context.tr('limit.pageTitle')}'),
              ),
              PopupMenuItem(
                value: 'recurring',
                child: Text('🔁 ${context.tr('recurring.title')}'),
              ),
              PopupMenuItem(
                value: 'rules',
                child: Text('🏷️ ${context.tr('rules.title')}'),
              ),
              PopupMenuItem(
                value: 'import',
                child: Text('📥 ${context.tr('csv.title')}'),
              ),
              PopupMenuItem(
                value: 'csv',
                child: Text('📄 ${context.tr('money.exportCsv')}'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-money',
        onPressed: () => AddTransactionSheet.show(context),
        icon: const Icon(Icons.add),
        label: Text(context.tr('common.add')),
      ),
      body: AnimatedBackdrop(
        style: BackdropStyle.coins,
        color: LifeColors.finance,
        child: transactions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Something went wrong: $e')),
        data: (list) {
          final sorted = [...list]..sort((a, b) => b.date.compareTo(a.date));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _BalanceHeader(budget: budget),
              const SizedBox(height: 12),
              const _SmartFinanceCard(),
              const SizedBox(height: 12),
              const _FinanceTipCard(),
              const SizedBox(height: 12),
              const _MonthlyTrendCard(),
              const SizedBox(height: 12),
              const _CategoryBreakdownCard(),
              const SizedBox(height: 12),
              const _MonthComparisonCard(),
              const SizedBox(height: 12),
              const _SpendingCalendarCard(),
              const SizedBox(height: 16),
              Text(context.tr('money.history'),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const _HistoryControls(),
              const SizedBox(height: 8),
              _HistoryList(all: sorted),
            ],
          );
        },
        ),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final list = ref.read(transactionsProvider).valueOrNull ?? const [];
    if (list.isEmpty) return;
    final csv = buildTransactionsCsv(list);
    final stamp = DateTime.now().toIso8601String().split('T').first;
    final downloaded = downloadTextFile('lifeos-transactions-$stamp.csv', csv);
    if (!downloaded) await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(context.tr(
            downloaded ? 'money.csvDownloaded' : 'money.csvCopied')),
      ));
  }
}

class _BalanceHeader extends StatelessWidget {
  final Budget budget;
  const _BalanceHeader({required this.budget});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      colors: LifeGradients.finance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('money.availableThisMonth'),
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          AnimatedCounter(
            value: budget.available.major,
            format: (v) => Money.fromMajor(
              v,
              currency: budget.available.currency,
            ).format(),
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: budget.spendProgress.clamp(0.0, 1.0).toDouble(),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat(context, context.tr('money.income'), budget.income.format()),
              _stat(context, context.tr('money.spent'), budget.expenses.format()),
              _stat(
                  context, context.tr('money.reserve'), budget.reserve.format()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }
}

/// "Smart finance" — the analyzer's plain-language verdicts about pace,
/// month-end projection, what to squeeze, and goal impact.
class _SmartFinanceCard extends ConsumerWidget {
  const _SmartFinanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(smartFinanceProvider);
    if (insights.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🧠 ${context.tr('smart.title')}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final insight in insights)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr(insight.titleKey),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: insight.positive
                                  ? LifeColors.finance
                                  : null,
                            )),
                        Text(
                          context.trp(insight.msgKey, {
                            ...insight.params,
                            if (insight.params['catId'] != null)
                              'cat': context
                                  .tr(insight.params['catId']! as String),
                          }),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A single evergreen money tip, rotated daily.
class _FinanceTipCard extends ConsumerWidget {
  const _FinanceTipCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipKey = ref.watch(financeTipProvider);
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('smart.tipTitle'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(context.tr(tipKey),
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 6-month income vs expense bars — custom painted, no chart package.
class _MonthlyTrendCard extends ConsumerWidget {
  const _MonthlyTrendCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(monthlySeriesProvider);
    if (series.every((e) => e.$2 == 0 && e.$3 == 0)) {
      return const SizedBox.shrink();
    }
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('money.trend'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(painter: _BarsPainter(series)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final (month, _, _) in series)
                Text(DateFormat.MMM().format(month),
                    style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  final List<(DateTime, int, int)> series;
  _BarsPainter(this.series);

  @override
  void paint(Canvas canvas, Size size) {
    var max = 1;
    for (final (_, inc, exp) in series) {
      if (inc > max) max = inc;
      if (exp > max) max = exp;
    }
    final groupW = size.width / series.length;
    final barW = groupW * 0.28;
    final income = Paint()..color = LifeColors.finance;
    final expense = Paint()..color = LifeColors.financeDanger;

    for (var i = 0; i < series.length; i++) {
      final (_, inc, exp) = series[i];
      final cx = groupW * i + groupW / 2;
      final incH = size.height * inc / max;
      final expH = size.height * exp / max;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - barW - 2, size.height - incH, barW, incH),
          const Radius.circular(3),
        ),
        income,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + 2, size.height - expH, barW, expH),
          const Radius.circular(3),
        ),
        expense,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) => old.series != series;
}

/// This month's spending by category with share bars.
class _CategoryBreakdownCard extends ConsumerWidget {
  const _CategoryBreakdownCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(categorySpendingProvider);
    if (items.isEmpty) return const SizedBox.shrink();
    final total = items.fold(0, (s, e) => s + e.$2.minorUnits);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('money.byCategory'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final (category, amount) in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(category.emoji),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: Text(context.tr('cat.${category.id}'),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : amount.minorUnits / total,
                        minHeight: 8,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(amount.format(),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// This month vs. last month, with the category that moved the most.
class _MonthComparisonCard extends ConsumerWidget {
  const _MonthComparisonCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(monthComparisonProvider);
    if (c.thisSpent == 0 && !c.hasLast) return const SizedBox.shrink();
    final pct = c.pctChange;
    final down = c.delta <= 0;
    final color = down ? LifeColors.finance : LifeColors.financeDanger;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('money.vsLastMonth'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(down ? Icons.trending_down : Icons.trending_up,
                  color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pct == null
                      ? context.trp('money.spentThisMonth',
                          {'amount': Money(c.thisSpent).format()})
                      : context.trp(
                          down ? 'money.lessThanLast' : 'money.moreThanLast',
                          {
                              'pct': pct.abs(),
                              'amount': Money(c.thisSpent).format(),
                            }),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (c.topMoverCategory != null && c.topMoverDelta.abs() > 0) ...[
            const SizedBox(height: 6),
            Text(
              context.trp('money.biggestChange', {
                'cat': context.tr('cat.${c.topMoverCategory}'),
                'sign': c.topMoverDelta >= 0 ? '+' : '−',
                'amount': Money(c.topMoverDelta.abs()).format(),
              }),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A calendar heatmap of this month's daily spending.
class _SpendingCalendarCard extends ConsumerWidget {
  const _SpendingCalendarCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailySpendingProvider);
    if (daily.isEmpty) return const SizedBox.shrink();
    final now = ref.watch(clockProvider).now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leading = DateTime(now.year, now.month, 1).weekday - 1; // Mon=0
    var maxSpend = 1;
    for (final v in daily.values) {
      if (v > maxSpend) maxSpend = v;
    }

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('money.calendar'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (var i = 0; i < leading; i++) const SizedBox.shrink(),
              for (var day = 1; day <= daysInMonth; day++)
                _CalendarCell(
                  day: day,
                  spent: daily[day] ?? 0,
                  intensity: (daily[day] ?? 0) / maxSpend,
                  isToday: day == now.day,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  final int day;
  final int spent;
  final double intensity;
  final bool isToday;
  const _CalendarCell({
    required this.day,
    required this.spent,
    required this.intensity,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final bg = spent == 0
        ? base.withValues(alpha: 0.4)
        : LifeColors.financeDanger.withValues(alpha: 0.2 + 0.8 * intensity);
    final onBg = spent == 0 || intensity < 0.5
        ? Theme.of(context).colorScheme.onSurface
        : Colors.white;
    return Tooltip(
      message: spent == 0 ? '$day' : '$day · ${Money(spent).format()}',
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: isToday
              ? Border.all(color: LifeColors.finance, width: 1.5)
              : null,
        ),
        child: Text('$day',
            style: TextStyle(fontSize: 11, color: onBg)),
      ),
    );
  }
}

/// Search box + income/expense filter chips for the history.
class _HistoryControls extends ConsumerStatefulWidget {
  const _HistoryControls();

  @override
  ConsumerState<_HistoryControls> createState() => _HistoryControlsState();
}

class _HistoryControlsState extends ConsumerState<_HistoryControls> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(txTypeFilterProvider);
    return Column(
      children: [
        TextField(
          controller: _controller,
          onChanged: (v) => ref.read(txQueryProvider.notifier).state = v,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: context.tr('money.search'),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      ref.read(txQueryProvider.notifier).state = '';
                      setState(() {});
                    },
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (label, value) in [
              (context.tr('money.filterAll'), null),
              (context.tr('money.income'), TransactionType.income),
              (context.tr('money.expense'), TransactionType.expense),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: filter == value,
                  onSelected: (_) =>
                      ref.read(txTypeFilterProvider.notifier).state = value,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// The filtered transaction list (search + type), with swipe-to-delete.
class _HistoryList extends ConsumerWidget {
  final List<Transaction> all;
  const _HistoryList({required this.all});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(txQueryProvider).trim().toLowerCase();
    final type = ref.watch(txTypeFilterProvider);
    final filtered = [
      for (final t in all)
        if (type == null || t.type == type)
          if (query.isEmpty || _matches(context, t, query)) t,
    ];

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(all.isEmpty
              ? context.tr('money.noTransactions')
              : context.tr('money.noMatches')),
        ),
      );
    }

    return Column(
      children: [
        for (final t in filtered)
          Dismissible(
            key: ValueKey(t.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: LifeColors.financeDanger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.delete, color: LifeColors.financeDanger),
            ),
            onDismissed: (_) async {
              await ref.read(removeTransactionProvider).call(t);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                      SnackBar(content: Text(context.tr('money.deleted'))));
              }
            },
            child: _TransactionTile(transaction: t),
          ),
      ],
    );
  }

  bool _matches(BuildContext context, Transaction t, String q) {
    final cat = context.tr('cat.${t.category.id}').toLowerCase();
    return t.note.toLowerCase().contains(q) ||
        cat.contains(q) ||
        t.amount.major.toStringAsFixed(2).contains(q);
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final category = transaction.category;
    final isIncome = transaction.isIncome;
    final color = isIncome ? LifeColors.finance : LifeColors.financeDanger;
    final sign = isIncome ? '+' : '−';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => AddTransactionSheet.show(context, initial: transaction),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text(category.emoji),
      ),
      title: Text(context.tr('cat.${category.id}')),
      subtitle: Text(
        [
          DateFormat.MMMd().format(transaction.date),
          if (transaction.note.isNotEmpty) transaction.note,
        ].join(' · '),
      ),
      trailing: Text(
        '$sign${transaction.amount.format()}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

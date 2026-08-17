import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/constants/app_constants.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/utils/download_file.dart';
import 'package:lifeos/features/money/application/transaction_csv.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/features/money/presentation/pages/budget_limits_page.dart';
import 'package:lifeos/features/money/presentation/pages/category_rules_page.dart';
import 'package:lifeos/features/money/presentation/pages/csv_import_page.dart';
import 'package:lifeos/features/money/presentation/pages/receipt_page.dart';
import 'package:lifeos/features/money/presentation/pages/recurring_page.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/features/money/presentation/widgets/add_transaction_sheet.dart';
import 'package:lifeos/features/rooms/domain/life_room.dart';
import 'package:lifeos/features/rooms/presentation/widgets/room_scaffold.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// MoneyOS home — the balance header plus the full transaction history. Adding a
/// transaction flows through the event pipeline and this list updates reactively.
class MoneyPage extends ConsumerWidget {
  const MoneyPage({super.key});

  /// The room's one sentence: the strongest finance insight, phrased as a
  /// conclusion. Falls back to the evergreen tip when there's nothing to say.
  String _voice(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(smartFinanceProvider);
    if (insights.isEmpty) return ref.watch(financeTipProvider);
    final top = insights.first;
    return context.trp(top.msgKey, {
      ...top.params,
      if (top.params['catId'] != null)
        'cat': context.tr(top.params['catId']! as String),
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);
    final budget = ref.watch(currentBudgetProvider);
    final room = roomById(RoomId.money);
    final accent = room.colorFor(Theme.of(context).brightness);
    final sorted = [
      ...?transactions.valueOrNull,
    ]..sort((a, b) => b.date.compareTo(a.date));

    final spendable =
        budget.income.minorUnits - budget.reserve.minorUnits;
    final spent = budget.expenses.minorUnits;

    return RoomScaffold(
      room: room,
      title: context.tr('nav.money'),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-money',
        onPressed: () => AddTransactionSheet.show(context),
        icon: const Icon(Icons.add),
        label: Text(context.tr('common.add')),
      ),
      hero: RoomHero(
        label: context.tr('today.safeToSpend'),
        value: budget.safeToSpendToday.format(),
        accent: accent,
        progress: spendable <= 0 ? null : spent / spendable,
        caption: context.trp('money.heroCaption', {
          'spent': budget.expenses.format(),
          'total': budget.income.format(),
        }),
      ),
      voice: _voice(context, ref),
      actions: [
        RoomAction(
          icon: Icons.remove,
          label: context.tr('money.expense'),
          onTap: () => AddTransactionSheet.show(context),
        ),
        RoomAction(
          icon: Icons.add,
          label: context.tr('money.income'),
          onTap: () => AddTransactionSheet.show(context),
        ),
        RoomAction(
          icon: Icons.receipt_long,
          label: context.tr('receipt.title'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ReceiptPage()),
          ),
        ),
      ],
      tools: [
        RoomTool(
          icon: Icons.tune,
          label: context.tr('limit.title'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const BudgetLimitsPage()),
          ),
        ),
        RoomTool(
          icon: Icons.repeat,
          label: context.tr('recurring.title'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const RecurringPage()),
          ),
        ),
        RoomTool(
          icon: Icons.sell_outlined,
          label: context.tr('rules.title'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CategoryRulesPage()),
          ),
        ),
        RoomTool(
          icon: Icons.download_outlined,
          label: context.tr('money.importCsv'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CsvImportPage()),
          ),
        ),
        RoomTool(
          icon: Icons.ios_share,
          label: context.tr('money.exportCsv'),
          onTap: () => _exportCsv(context, ref),
        ),
      ],
      children: [
        // The strongest verdict is the room's voice; the rest stay here so no
        // advice is lost to the shorter layout.
        const _MoreInsightsCard(),
        // The four charts (trend, categories, comparison, calendar) live
        // together in one popup so the room stays short.
        _AnalyticsEntry(onTap: () => _showAnalyticsSheet(context)),
        const SizedBox(height: 16),
        Text(context.tr('money.history'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        // Search and filters are noise until there is something to search.
        if (sorted.isNotEmpty) ...[
          const _HistoryControls(),
          const SizedBox(height: 8),
        ],
        if (transactions.isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ))
        else
          _HistoryList(all: sorted),
      ],
    );
  }
}

Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
  final list = ref.read(transactionsProvider).valueOrNull ?? const [];
  if (list.isEmpty) return;
  final csv = buildTransactionsCsv(list);
  final stamp = DateTime.now().toIso8601String().split('T').first;
  final downloaded = downloadTextFile(
      '${AppConstants.brandSlug}-transactions-$stamp.csv', csv);
  if (!downloaded) await Clipboard.setData(ClipboardData(text: csv));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(
          context.tr(downloaded ? 'money.csvDownloaded' : 'money.csvCopied')),
    ));
}

/// The finance verdicts that didn't make it into the room's voice line. The
/// first insight is already the voice, so this starts at the second — the
/// advice is shortened, never dropped.
class _MoreInsightsCard extends ConsumerWidget {
  const _MoreInsightsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rest = ref.watch(smartFinanceProvider).skip(1).toList();
    if (rest.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🧠 ${context.tr('smart.title')}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            for (final insight in rest)
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
      ),
    );
  }
}

/// Compact entry that opens all four money charts in one popup, keeping the
/// main screen short.
class _AnalyticsEntry extends StatelessWidget {
  final VoidCallback onTap;
  const _AnalyticsEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Text('📊', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('money.analytics'),
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  context.tr('money.analyticsSub'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

/// The four charts grouped into one scrollable popup.
void _showAnalyticsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(ctx.tr('money.analytics'),
              style: Theme.of(ctx).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const _MonthlyTrendCard(),
          const SizedBox(height: 12),
          const _CategoryBreakdownCard(),
          const SizedBox(height: 12),
          const _MonthComparisonCard(),
          const SizedBox(height: 12),
          const _SpendingCalendarCard(),
        ],
      ),
    ),
  );
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
            InkWell(
              onTap: () => _showCategoryItems(context, ref, category),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
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
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Drill-down: this month's individual expenses in one category (e.g. every
/// food item bought and its price), newest-largest first. This is what turns
/// "Food — $42" into "Milk $1.20 · Bread $0.80 · …".
void _showCategoryItems(BuildContext context, WidgetRef ref, Category category) {
  final now = ref.read(clockProvider).now();
  final all = ref.read(transactionsProvider).valueOrNull ?? const [];
  final items = [
    for (final t in all)
      if (t.isExpense &&
          t.categoryId == category.id &&
          t.date.year == now.year &&
          t.date.month == now.month)
        t,
  ]..sort((a, b) => b.amount.minorUnits.compareTo(a.amount.minorUnits));
  final total = items.fold(0, (s, t) => s + t.amount.minorUnits);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Row(
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(ctx.tr('cat.${category.id}'),
                    style: Theme.of(ctx).textTheme.headlineSmall),
              ),
              Text(Money(total).format(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(ctx.tr('money.categoryEmpty'),
                style: Theme.of(ctx).textTheme.bodyMedium)
          else
            for (final t in items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  t.note.trim().isEmpty
                      ? ctx.tr('cat.${t.categoryId}')
                      : t.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(DateFormat.MMMd().format(t.date)),
                trailing: Text(t.amount.format(),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
        ],
      ),
    ),
  );
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
        // Wrap, not Row: the three Russian labels are 15px wider than a 360px
        // phone, and a fixed Row has nowhere to put the overflow.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, value) in [
              (context.tr('money.filterAll'), null),
              (context.tr('money.income'), TransactionType.income),
              (context.tr('money.expense'), TransactionType.expense),
            ])
              ChoiceChip(
                label: Text(label),
                selected: filter == value,
                onSelected: (_) =>
                    ref.read(txTypeFilterProvider.notifier).state = value,
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

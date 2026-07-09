import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/presentation/providers/budget_limits_providers.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';

/// Set a monthly spending ceiling per category. When this month's spend crosses
/// a limit you get a notification (and phone push).
class BudgetLimitsPage extends ConsumerWidget {
  const BudgetLimitsPage({super.key});

  static const _expenseCats = [
    DefaultCategories.food,
    DefaultCategories.transport,
    DefaultCategories.home,
    DefaultCategories.fun,
    DefaultCategories.health,
    DefaultCategories.other,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limits = ref.watch(categoryLimitsProvider);
    final spendByCat = {
      for (final (c, m) in ref.watch(categorySpendingProvider)) c.id: m,
    };

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('limit.pageTitle'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.coins,
        color: LifeColors.finance,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(context.tr('limit.intro'),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            for (final c in _expenseCats)
              _row(
                context,
                ref,
                c,
                spendByCat[c.id] ?? const Money.zero(),
                limits[c.id] == null ? null : Money(limits[c.id]!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, Category c, Money spent,
      Money? limit) {
    final ratio = limit == null || limit.minorUnits == 0
        ? 0.0
        : (spent.minorUnits / limit.minorUnits).clamp(0.0, 1.0);
    final over = limit != null && spent.minorUnits > limit.minorUnits;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(c.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(child: Text(context.tr('cat.${c.id}'))),
                TextButton(
                  onPressed: () => _editLimit(context, ref, c, limit),
                  child: Text(limit == null
                      ? context.tr('limit.set')
                      : limit.format()),
                ),
              ],
            ),
            if (limit != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  color: over ? LifeColors.financeDanger : null,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.trp('limit.spentOf',
                    {'spent': spent.format(), 'limit': limit.format()}),
                style: TextStyle(
                  fontSize: 12,
                  color: over ? LifeColors.financeDanger : null,
                  fontWeight: over ? FontWeight.w700 : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editLimit(
      BuildContext context, WidgetRef ref, Category c, Money? current) async {
    final controller = TextEditingController(
        text: current == null ? '' : current.major.toStringAsFixed(0));
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${c.emoji} ${ctx.tr('cat.${c.id}')}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: ctx.tr('limit.monthlyLimit'),
            hintText: '0 = ${ctx.tr('limit.noLimit')}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text) ?? 0),
            child: Text(ctx.tr('common.save')),
          ),
        ],
      ),
    );
    if (result == null) return;
    ref
        .read(categoryLimitsProvider.notifier)
        .setLimit(c.id, Money.fromMajor(result).minorUnits);
  }
}

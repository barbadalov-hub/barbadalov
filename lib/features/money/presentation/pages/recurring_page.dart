import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/recurring_rule.dart';
import 'package:lifeos/features/money/presentation/providers/recurring_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';

/// Manage recurring income/expenses (salary, rent, subscriptions). They post
/// themselves automatically each month.
class RecurringPage extends ConsumerWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(recurringProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('recurring.title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSheet(context, ref),
        icon: const Icon(Icons.add),
        label: Text(context.tr('recurring.add')),
      ),
      body: AnimatedBackdrop(
        style: BackdropStyle.coins,
        color: LifeColors.finance,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(context.tr('recurring.intro'),
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            if (rules.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(context.tr('recurring.empty'),
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              )
            else
              for (final r in rules) _tile(context, ref, r),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, RecurringRule r) {
    final income = r.type == TransactionType.income;
    final color = income ? LifeColors.finance : LifeColors.financeDanger;
    final cat = DefaultCategories.byId(r.categoryId);
    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => ref.read(recurringProvider.notifier).remove(r.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: LifeColors.financeDanger,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        child: ListTile(
          leading: Text(cat.emoji, style: const TextStyle(fontSize: 24)),
          title: Text(r.label.isEmpty ? context.tr('cat.${cat.id}') : r.label),
          subtitle: Text(context.trp('recurring.everyDay', {'n': r.dayOfMonth})),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${income ? '+' : '−'}${r.amount.format()}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              Switch(
                value: r.active,
                onChanged: (_) =>
                    ref.read(recurringProvider.notifier).toggle(r.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RecurringForm(
        onCreate: (label, type, minor, catId, day) =>
            ref.read(recurringProvider.notifier).addNew(
                  label: label,
                  type: type,
                  amountMinor: minor,
                  categoryId: catId,
                  dayOfMonth: day,
                ),
      ),
    );
  }
}

class _RecurringForm extends StatefulWidget {
  final void Function(
      String label, TransactionType type, int minor, String catId, int day)
  onCreate;
  const _RecurringForm({required this.onCreate});

  @override
  State<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends State<_RecurringForm> {
  final _label = TextEditingController();
  final _amount = TextEditingController();
  TransactionType _type = TransactionType.expense;
  late String _catId = DefaultCategories.food.id;
  int _day = 1;

  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    super.dispose();
  }

  List<Category> get _cats => DefaultCategories.of(_type);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('recurring.add'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SegmentedButton<TransactionType>(
            segments: [
              ButtonSegment(
                  value: TransactionType.expense,
                  label: Text(context.tr('money.expense'))),
              ButtonSegment(
                  value: TransactionType.income,
                  label: Text(context.tr('money.income'))),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() {
              _type = s.first;
              _catId = _cats.first.id;
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _label,
            decoration: InputDecoration(
              labelText: context.tr('recurring.label'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: context.tr('money.amount'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _catId,
            decoration: InputDecoration(
              labelText: context.tr('money.category'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final c in _cats)
                DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.emoji} ${context.tr('cat.${c.id}')}')),
            ],
            onChanged: (v) => setState(() => _catId = v ?? _catId),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(context.tr('recurring.dayOfMonth'))),
              IconButton.filledTonal(
                onPressed: _day > 1 ? () => setState(() => _day--) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 40,
                child: Text('$_day',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              IconButton.filledTonal(
                onPressed: _day < 28 ? () => setState(() => _day++) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final minor =
                    Money.fromMajor(int.tryParse(_amount.text) ?? 0).minorUnits;
                if (minor <= 0) return;
                widget.onCreate(_label.text.trim(), _type, minor, _catId, _day);
                Navigator.of(context).pop();
              },
              child: Text(context.tr('common.add')),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/shared/models/money.dart';

/// Bottom sheet for recording income or an expense — or editing an existing
/// transaction when [initial] is set. On submit it calls the Add/Update use
/// case, which persists and **publishes a LifeEvent** — the UI itself contains
/// no money logic.
class AddTransactionSheet extends ConsumerStatefulWidget {
  final Transaction? initial;
  const AddTransactionSheet({this.initial, super.key});

  static Future<void> show(BuildContext context, {Transaction? initial}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => AddTransactionSheet(initial: initial),
      );

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late final _amountController = TextEditingController(
    text: widget.initial == null ? '' : _majorText(widget.initial!),
  );
  late final _noteController =
      TextEditingController(text: widget.initial?.note ?? '');
  late TransactionType _type =
      widget.initial?.type ?? TransactionType.expense;
  late Category _category = widget.initial == null
      ? DefaultCategories.of(_type).first
      : DefaultCategories.byId(widget.initial!.categoryId);
  bool _submitting = false;

  static String _majorText(Transaction t) {
    final major = t.amount.major;
    return major == major.roundToDouble()
        ? '${major.round()}'
        : major.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      _category = DefaultCategories.of(type).first;
    });
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _showError(context.tr('money.amountError'));
      return;
    }

    setState(() => _submitting = true);
    final initial = widget.initial;
    final result = initial == null
        ? await ref.read(addTransactionProvider).call(
              amount: Money.fromMajor(amount),
              type: _type,
              categoryId: _category.id,
              note: _noteController.text,
            )
        : await ref.read(updateTransactionProvider).call(Transaction(
              id: initial.id,
              amount: Money.fromMajor(amount,
                  currency: initial.amount.currency),
              type: _type,
              categoryId: _category.id,
              note: _noteController.text.trim(),
              date: initial.date,
            ));
    if (!mounted) return;
    setState(() => _submitting = false);

    result.fold(
      (failure) {
        _showError(failure.message);
      },
      (_) {
        Navigator.of(context).pop();
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final categories = DefaultCategories.of(_type);
    final insets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + insets),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<TransactionType>(
            segments: [
              ButtonSegment(
                value: TransactionType.expense,
                label: Text(context.tr('money.expense')),
                icon: const Icon(Icons.south_west),
              ),
              ButtonSegment(
                value: TransactionType.income,
                label: Text(context.tr('money.income')),
                icon: const Icon(Icons.north_east),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (s) => _onTypeChanged(s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: Theme.of(context).textTheme.headlineMedium,
            decoration: const InputDecoration(
              prefixText: '\$ ',
              hintText: '0.00',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(context.tr('money.category'),
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in categories)
                ChoiceChip(
                  label: Text('${c.emoji} ${context.tr('cat.${c.id}')}'),
                  selected: _category.id == c.id,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: context.tr('common.note'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.initial != null
                    ? context.tr('common.save')
                    : _type == TransactionType.income
                        ? context.tr('money.addIncome')
                        : context.tr('money.addExpense')),
          ),
        ],
      ),
    );
  }
}

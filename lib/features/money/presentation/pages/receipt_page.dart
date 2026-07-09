import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/ocr_gateway.dart';
import 'package:lifeos/features/money/application/receipt_parser.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/receipt.dart';
import 'package:lifeos/features/money/presentation/providers/category_rules_providers.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/features/money/presentation/widgets/add_transaction_sheet.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// Add a receipt by pasting/typing its text; it's analysed offline into an
/// itemised, categorised breakdown you can tweak and save as expenses. No
/// receipt? One tap opens manual entry instead.
class ReceiptPage extends ConsumerStatefulWidget {
  const ReceiptPage({super.key});

  @override
  ConsumerState<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends ConsumerState<ReceiptPage> {
  final _input = TextEditingController();
  List<ReceiptItem> _items = [];
  Money? _detectedTotal;
  bool _analyzed = false;

  static const _expenseCats = [
    DefaultCategories.food,
    DefaultCategories.transport,
    DefaultCategories.home,
    DefaultCategories.health,
    DefaultCategories.fun,
    DefaultCategories.other,
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  ParsedReceipt get _receipt =>
      ParsedReceipt(items: _items, detectedTotal: _detectedTotal);

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _input.text = data!.text!;
      setState(() {});
    }
  }

  void _analyze() {
    final parsed = const ReceiptParser().parse(_input.text);
    setState(() {
      _items = parsed.items;
      _detectedTotal = parsed.detectedTotal;
      _analyzed = true;
    });
  }

  bool _scanning = false;

  Future<void> _scan(OcrSource source) async {
    setState(() => _scanning = true);
    final text = await ocrGateway.scan(source);
    if (!mounted) return;
    setState(() => _scanning = false);
    if (text == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text(context.tr('receipt.scanFailed'))));
      return;
    }
    _input.text = text;
    _analyze();
  }

  void _setCategory(int index, String categoryId) {
    setState(() => _items[index] = _items[index].copyWith(categoryId: categoryId));
  }

  /// Apply the user's auto-categorize rules over the parser's guesses — a rule
  /// match (by item name) wins.
  void _applyRules() {
    final categorize = ref.read(categorizeProvider);
    var changed = false;
    final next = [
      for (final item in _items)
        if (categorize(item.name) case final id?)
          () {
            changed = true;
            return item.copyWith(categoryId: id);
          }()
        else
          item,
    ];
    if (changed) setState(() => _items = next);
  }

  Future<void> _save() async {
    _applyRules();
    final add = ref.read(addTransactionProvider);
    final groups = _receipt.byCategory;
    for (final (category, amount) in groups) {
      if (!amount.isPositive) continue;
      await add.call(
        amount: amount,
        type: TransactionType.expense,
        categoryId: category.id,
        note: context.tr('receipt.noteFromReceipt'),
      );
    }
    if (!mounted) return;
    final count = groups.where((g) => g.$2.isPositive).length;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text(context.trp('receipt.saved', {'n': count}))));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('receipt.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.coins,
        color: LifeColors.finance,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(context.tr('receipt.intro'),
                style: Theme.of(context).textTheme.bodySmall),
            if (ocrGateway.available) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _scanning
                          ? null
                          : () => _scan(OcrSource.camera),
                      icon: _scanning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.photo_camera),
                      label: Text(context.tr('receipt.scanCamera')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _scanning ? null : () => _scan(OcrSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: Text(context.tr('receipt.scanGallery')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(context.tr('receipt.scanNote'),
                  style: Theme.of(context).textTheme.labelSmall),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _input,
              minLines: 4,
              maxLines: 10,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: context.tr('receipt.hint'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _paste,
                  icon: const Icon(Icons.paste),
                  label: Text(context.tr('receipt.paste')),
                ),
                FilledButton.icon(
                  onPressed: _analyze,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(context.tr('receipt.analyze')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => AddTransactionSheet.show(context),
              icon: const Icon(Icons.edit_note),
              label: Text(context.tr('receipt.manual')),
            ),
            if (_analyzed) ...[
              const SizedBox(height: 12),
              if (_items.isEmpty)
                SectionCard(
                  child: Row(
                    children: [
                      const Text('🤔', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(context.tr('receipt.nothing'))),
                    ],
                  ),
                )
              else
                _buildResult(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final computed = _receipt.computedTotal;
    final detected = _detectedTotal;
    final mismatch = detected != null && detected != computed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Per-category summary — "what you spent it on".
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('receipt.breakdown'),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final (category, amount) in _receipt.byCategory)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(category.emoji),
                      const SizedBox(width: 8),
                      Expanded(child: Text(context.tr('cat.${category.id}'))),
                      Text(amount.format(),
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.tr('receipt.total'),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(_receipt.total.format(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
              if (mismatch)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    context.trp('receipt.mismatch', {
                      'computed': computed.format(),
                      'detected': detected.format(),
                    }),
                    style: const TextStyle(
                        fontSize: 12, color: LifeColors.financeDanger),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(context.trp('receipt.items', {'n': _items.length}),
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        // Editable item list — fix a wrong category before saving.
        for (var i = 0; i < _items.length; i++) _itemTile(context, i),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: Text(context.tr('receipt.save')),
          ),
        ),
      ],
    );
  }

  Widget _itemTile(BuildContext context, int i) {
    final item = _items[i];
    return Card(
      child: ListTile(
        dense: true,
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            if (item.qty != 1)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text('×${_qty(item.qty)}'),
              ),
            DropdownButton<String>(
              value: item.categoryId,
              isDense: true,
              underline: const SizedBox.shrink(),
              onChanged: (v) => v == null ? null : _setCategory(i, v),
              items: [
                for (final c in _expenseCats)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.emoji} ${context.tr('cat.${c.id}')}',
                        style: const TextStyle(fontSize: 13)),
                  ),
              ],
            ),
          ],
        ),
        trailing: Text(item.price.format(),
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  String _qty(double q) => q == q.roundToDouble() ? '${q.round()}' : '$q';
}

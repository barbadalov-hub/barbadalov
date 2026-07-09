import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/money/application/transaction_csv.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/presentation/providers/category_rules_providers.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// Import transactions from CSV (our export format, or a simple bank export).
/// Categories are matched by name, then by the user's auto-categorize rules.
class CsvImportPage extends ConsumerStatefulWidget {
  const CsvImportPage({super.key});

  @override
  ConsumerState<CsvImportPage> createState() => _CsvImportPageState();
}

class _CsvImportPageState extends ConsumerState<CsvImportPage> {
  final _input = TextEditingController();
  List<ParsedCsvRow> _rows = [];
  bool _parsed = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _input.text = data!.text!;
      setState(() {});
    }
  }

  void _parse() {
    setState(() {
      _rows = parseTransactionsCsv(_input.text);
      _parsed = true;
    });
  }

  Future<void> _import() async {
    final add = ref.read(addTransactionProvider);
    final categorize = ref.read(categorizeProvider);
    for (final r in _rows) {
      final categoryId = categoryIdForName(r.categoryName) ??
          categorize(r.note) ??
          (r.type == TransactionType.income
              ? DefaultCategories.otherIncome.id
              : DefaultCategories.other.id);
      await add.call(
        amount: Money(r.amountMinor, currency: r.currency),
        type: r.type,
        categoryId: categoryId,
        note: r.note,
        date: r.date,
      );
    }
    if (!mounted) return;
    final n = _rows.length;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text(context.trp('csv.imported', {'n': n}))));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('csv.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.coins,
        color: LifeColors.finance,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(context.tr('csv.intro'),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            TextField(
              controller: _input,
              minLines: 4,
              maxLines: 8,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: 'Date,Type,Category,Amount,Currency,Note',
                border: OutlineInputBorder(),
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
                  label: Text(context.tr('backup.paste')),
                ),
                FilledButton.icon(
                  onPressed: _parse,
                  icon: const Icon(Icons.search),
                  label: Text(context.tr('csv.parse')),
                ),
              ],
            ),
            if (_parsed) ...[
              const SizedBox(height: 14),
              if (_rows.isEmpty)
                SectionCard(child: Text(context.tr('csv.nothing')))
              else ...[
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.trp('csv.found', {'n': _rows.length}),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      for (final r in _rows.take(5))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${r.date.toIso8601String().split('T').first} · '
                            '${r.type == TransactionType.income ? '+' : '−'}'
                            '${Money(r.amountMinor, currency: r.currency).format()} · '
                            '${r.categoryName.isEmpty ? '—' : r.categoryName}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (_rows.length > 5)
                        Text('…',
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.download_done),
                    label: Text(context.trp('csv.importN', {'n': _rows.length})),
                    onPressed: _import,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

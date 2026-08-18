import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/money/presentation/providers/cash_providers.dart';
import 'package:lifeos/shared/models/money.dart';

/// Asks the one question the app cannot answer for itself: how much is there.
///
/// Deliberately a single field. Splitting it per account would be more precise
/// and would get abandoned halfway; one honest total beats three empty ones.
class BalanceSheet extends ConsumerStatefulWidget {
  const BalanceSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const BalanceSheet(),
      );

  @override
  ConsumerState<BalanceSheet> createState() => _BalanceSheetState();
}

class _BalanceSheetState extends ConsumerState<BalanceSheet> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final current = ref.read(cashPositionProvider);
    if (current.anchored) {
      _controller.text = current.onHand.major.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final typed = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (typed == null) return;
    ref.read(balanceAnchorProvider.notifier).record(Money.fromMajor(typed));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final anchored = ref.watch(cashPositionProvider).anchored;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('cash.askTitle'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            context.tr('cash.askHint'),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.outline, height: 1.35),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            autofocus: true,
            decoration: InputDecoration(
              labelText: context.tr('cash.amount'),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: Text(context.tr('cash.save')),
            ),
          ),
          if (anchored) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () {
                  ref.read(balanceAnchorProvider.notifier).forget();
                  Navigator.of(context).pop();
                },
                child: Text(context.tr('cash.forget')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

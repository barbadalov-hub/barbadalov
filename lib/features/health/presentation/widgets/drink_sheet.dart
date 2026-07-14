import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/presentation/providers/diet_providers.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';

/// A preset drink: how much water it adds (ml) and its calories (kcal, 0 for
/// plain water).
class _Drink {
  final String emoji;
  final String labelKey;
  final int ml;
  final int kcal;
  const _Drink(this.emoji, this.labelKey, this.ml, [this.kcal = 0]);
}

/// "What did you drink?" — logs hydration in millilitres (and calories for
/// coffee/tea) from a tap. Plain water goes to the health day; anything with
/// calories is also added to today's food diary.
class DrinkSheet extends ConsumerWidget {
  const DrinkSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const DrinkSheet(),
      );

  static const _water = <_Drink>[
    _Drink('🥛', 'drink.glass', 250),
    _Drink('🥤', 'drink.bigGlass', 350),
    _Drink('🍶', 'drink.bottle', 500),
    _Drink('🫗', 'drink.mug', 300),
  ];

  static const _beverages = <_Drink>[
    _Drink('☕', 'drink.espresso', 30, 3),
    _Drink('☕', 'drink.americano', 150, 5),
    _Drink('☕', 'drink.cappuccino', 180, 120),
    _Drink('☕', 'drink.latte', 240, 190),
    _Drink('☕', 'drink.raf', 220, 250),
    _Drink('🍵', 'drink.tea', 200, 2),
  ];

  void _log(BuildContext context, WidgetRef ref, String name, int ml,
      int kcal) {
    if (ml > 0) ref.read(logHealthProvider).addWaterMl(ml);
    if (kcal > 0) {
      ref.read(manualFoodProvider.notifier).add(
            name,
            NutritionFacts(kcal: kcal, proteinG: 0, fatG: 0, carbsG: 0),
          );
    }
    Navigator.of(context).maybePop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(kcal > 0
            ? context.trp('drink.added', {'name': name, 'ml': ml, 'kcal': kcal})
            : context.trp('drink.addedWater', {'ml': ml})),
      ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Text(context.tr('drink.title'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _header(context, '💧', context.tr('drink.water')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final d in _water)
                _DrinkChip(
                  drink: d,
                  onTap: () =>
                      _log(context, ref, context.tr(d.labelKey), d.ml, 0),
                ),
              _CustomChip(onTap: () => _custom(context, ref)),
            ],
          ),
          const SizedBox(height: 20),
          _header(context, '☕', context.tr('drink.drinks')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final d in _beverages)
                _DrinkChip(
                  drink: d,
                  onTap: () =>
                      _log(context, ref, context.tr(d.labelKey), d.ml, d.kcal),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String emoji, String title) => Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  )),
        ],
      );

  Future<void> _custom(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<(String, int, int)>(
      context: context,
      builder: (_) => const _CustomDrinkDialog(),
    );
    if (result == null || !context.mounted) return;
    final (name, ml, kcal) = result;
    _log(context, ref, name, ml, kcal);
  }
}

class _DrinkChip extends StatelessWidget {
  final _Drink drink;
  final VoidCallback onTap;
  const _DrinkChip({required this.drink, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sub = drink.kcal > 0
        ? '${drink.ml} ${context.tr('drink.ml')} · ${drink.kcal} ${context.tr('drink.kcal')}'
        : '${drink.ml} ${context.tr('drink.ml')}';
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Text(drink.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr(drink.labelKey),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(sub,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomChip extends StatelessWidget {
  final VoidCallback onTap;
  const _CustomChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.add, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Text(context.tr('drink.custom'))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom drink input: millilitres (required) plus optional name and calories.
class _CustomDrinkDialog extends StatefulWidget {
  const _CustomDrinkDialog();

  @override
  State<_CustomDrinkDialog> createState() => _CustomDrinkDialogState();
}

class _CustomDrinkDialogState extends State<_CustomDrinkDialog> {
  final _name = TextEditingController();
  final _ml = TextEditingController();
  final _kcal = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _ml.dispose();
    _kcal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('drink.custom')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: context.tr('drink.name')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _ml,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: context.tr('drink.mlLabel')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _kcal,
            keyboardType: TextInputType.number,
            decoration:
                InputDecoration(labelText: context.tr('drink.kcalLabel')),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('common.cancel')),
        ),
        FilledButton(
          onPressed: () {
            final ml = int.tryParse(_ml.text.trim()) ?? 0;
            if (ml <= 0) return;
            final kcal = int.tryParse(_kcal.text.trim()) ?? 0;
            final name = _name.text.trim().isEmpty
                ? context.tr('drink.customName')
                : _name.text.trim();
            Navigator.pop(context, (name, ml, kcal));
          },
          child: Text(context.tr('common.add')),
        ),
      ],
    );
  }
}

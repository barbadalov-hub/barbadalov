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

  // Popular soft/other drinks. Calories are typical values for the shown
  // serving; the custom estimator below derives kcal from ml for anything else.
  static const _soft = <_Drink>[
    _Drink('🥤', 'drink.cola', 330, 139),
    _Drink('🧃', 'drink.juice', 250, 110),
    _Drink('🥛', 'drink.milk', 250, 130),
    _Drink('🥛', 'drink.kefir', 250, 100),
    _Drink('🍫', 'drink.cocoa', 250, 190),
    _Drink('🥤', 'drink.smoothie', 300, 180),
    _Drink('⚡', 'drink.energy', 250, 113),
    _Drink('🧉', 'drink.kompot', 250, 90),
    _Drink('🍺', 'drink.beer', 500, 215),
    _Drink('🍷', 'drink.wine', 150, 125),
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
          const SizedBox(height: 20),
          _header(context, '🥤', context.tr('drink.soft')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final d in _soft)
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

/// Custom drink input: pick a beverage type and enter millilitres — the
/// calories are estimated automatically (typical kcal per 100 ml for that
/// type) and can still be overridden by hand.
class _CustomDrinkDialog extends StatefulWidget {
  const _CustomDrinkDialog();

  @override
  State<_CustomDrinkDialog> createState() => _CustomDrinkDialogState();
}

class _CustomDrinkDialogState extends State<_CustomDrinkDialog> {
  /// (i18n label, kcal per 100 ml) for common beverage families.
  static const _types = <(String, int)>[
    ('drink.type.water', 0),
    ('drink.type.tea', 1),
    ('drink.type.coffee', 2),
    ('drink.type.juice', 45),
    ('drink.type.soda', 42),
    ('drink.type.milk', 52),
    ('drink.type.beer', 43),
    ('drink.type.wine', 83),
    ('drink.type.other', 40),
  ];

  final _name = TextEditingController();
  final _ml = TextEditingController();
  final _kcal = TextEditingController();
  int _typeIndex = 0;
  bool _kcalEdited = false;

  @override
  void dispose() {
    _name.dispose();
    _ml.dispose();
    _kcal.dispose();
    super.dispose();
  }

  /// Re-estimate calories from ml × the type's density, unless the user has
  /// typed their own calorie value.
  void _recalc() {
    if (_kcalEdited) return;
    final ml = int.tryParse(_ml.text.trim()) ?? 0;
    final per100 = _types[_typeIndex].$2;
    final kcal = (ml * per100 / 100).round();
    _kcal.text = kcal == 0 ? '' : '$kcal';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('drink.custom')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: context.tr('drink.name')),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _typeIndex,
              isExpanded: true,
              decoration: InputDecoration(labelText: context.tr('drink.type')),
              items: [
                for (var i = 0; i < _types.length; i++)
                  DropdownMenuItem(
                      value: i, child: Text(context.tr(_types[i].$1))),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _typeIndex = v);
                _recalc();
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ml,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: context.tr('drink.mlLabel')),
              onChanged: (_) => _recalc(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _kcal,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.tr('drink.kcalLabel'),
                helperText: context.tr('drink.kcalAuto'),
              ),
              onChanged: (_) => _kcalEdited = true,
            ),
          ],
        ),
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
                ? context.tr(_types[_typeIndex].$1)
                : _name.text.trim();
            Navigator.pop(context, (name, ml, kcal));
          },
          child: Text(context.tr('common.add')),
        ),
      ],
    );
  }
}

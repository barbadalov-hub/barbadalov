import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/food/domain/entities/food_item.dart';
import 'package:lifeos/features/food/presentation/providers/food_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

class FoodPage extends ConsumerWidget {
  const FoodPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).now();
    final pantry = ref.watch(pantryProvider);
    final shopping = ref.watch(shoppingProvider);
    final recipes = ref.watch(recipesProvider);
    final mealPlan = ref.watch(mealPlanProvider);
    final foodBudget = ref.watch(foodBudgetProvider);
    final foodSpent = ref.watch(foodSpentThisMonthProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('more.food'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.orbs,
        color: LifeColors.finance,
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FoodBudgetCard(
            spent: foodSpent,
            target: foodBudget,
            onEdit: () => _editBudgetDialog(context, ref, foodBudget),
          ),
          const SizedBox(height: 20),
          const _PantryOverview(),
          const SizedBox(height: 12),
          _Header(
            title: context.tr('food.pantry'),
            onAdd: () => _addPantryDialog(context, ref),
          ),
          _QuickAddRow(
            items: const [
              ('🥛', 'qa.milk', 5),
              ('🥚', 'qa.eggs', 14),
              ('🍞', 'qa.bread', 3),
              ('🧀', 'qa.cheese', 10),
              ('🍎', 'qa.apples', 12),
              ('🍗', 'qa.chicken', 3),
            ],
            onPick: (emoji, name, days) => ref.read(addFoodItemProvider).call(
                  name: name,
                  emoji: emoji,
                  expiry:
                      ref.read(clockProvider).now().add(Duration(days: days!)),
                ),
          ),
          pantry.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (items) {
              if (items.isEmpty) {
                return _Empty(context.tr('food.pantryEmpty'));
              }
              final sorted = [...items]..sort(_byExpiry(now));
              return Column(
                children: [
                  for (final i in sorted) _PantryTile(item: i, now: now)
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _Header(
            title: context.tr('food.shopping'),
            onAdd: () => _addShoppingDialog(context, ref),
          ),
          _QuickAddRow(
            items: const [
              ('🍅', 'qa.tomatoes', null),
              ('🥔', 'qa.potatoes', null),
              ('🧅', 'qa.onion', null),
              ('🍌', 'qa.bananas', null),
              ('☕', 'qa.coffee', null),
              ('🧻', 'qa.paper', null),
            ],
            onPick: (emoji, name, _) =>
                ref.read(addShoppingItemProvider).call('$emoji $name'),
          ),
          shopping.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (items) {
              if (items.isEmpty) {
                return _Empty(context.tr('food.nothingToBuy'));
              }
              final bought = items.where((s) => s.checked).length;
              return Column(
                children: [
                  if (items.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: bought / items.length,
                                minHeight: 6,
                                color: LifeColors.finance,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('$bought/${items.length}',
                              style: Theme.of(context).textTheme.labelMedium),
                          if (bought > 0)
                            TextButton(
                              onPressed: () => ref
                                  .read(foodRepositoryProvider)
                                  .clearCheckedShopping(),
                              child: Text(context.tr('food.clearBought')),
                            ),
                        ],
                      ),
                    ),
                  ],
                  for (final s in items)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: s.checked,
                      onChanged: (_) =>
                          ref.read(toggleShoppingItemProvider).call(s),
                      title: Text(
                        s.name,
                        style: TextStyle(
                          decoration: s.checked
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _Header(
            title: context.tr('food.recipes'),
            onAdd: () => _addRecipeDialog(context, ref),
          ),
          recipes.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (list) {
              if (list.isEmpty) {
                return _Empty(context.tr('food.noRecipes'));
              }
              return Column(
                children: [
                  for (final r in list)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          Text(r.emoji, style: const TextStyle(fontSize: 22)),
                      title: Text(r.name),
                      subtitle: Text(r.ingredients.join(', ')),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        tooltip: context.tr('food.toShopping'),
                        onPressed: () {
                          ref.read(addRecipeToShoppingProvider).call(r);
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(
                                content:
                                    Text(context.tr('food.addedToShopping'))));
                        },
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(context.tr('food.mealPlan'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          mealPlan.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (plan) => Column(
              children: [
                for (var wd = 1; wd <= 7; wd++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: SizedBox(
                      width: 44,
                      child: Text(context.tr('food.wd.$wd'),
                          style: Theme.of(context).textTheme.labelLarge),
                    ),
                    title: Text(
                      plan.mealFor(wd).isEmpty ? '—' : plan.mealFor(wd),
                      style: plan.mealFor(wd).isEmpty
                          ? TextStyle(
                              color: Theme.of(context).colorScheme.outline)
                          : null,
                    ),
                    trailing: const Icon(Icons.edit, size: 18),
                    onTap: () =>
                        _editMealDialog(context, ref, wd, plan.mealFor(wd)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        ),
      ),
    );
  }

  int Function(FoodItem, FoodItem) _byExpiry(DateTime now) => (a, b) {
        final da = a.daysUntilExpiry(now) ?? 9999;
        final db = b.daysUntilExpiry(now) ?? 9999;
        return da.compareTo(db);
      };

  Future<void> _addPantryDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    var days = 7;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('food.addFood')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(labelText: ctx.tr('food.name')),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (_, setState) => Row(
                children: [
                  Text(ctx.tr('food.expiresIn')),
                  Expanded(
                    child: Slider(
                      value: days.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '$days d',
                      onChanged: (v) => setState(() => days = v.round()),
                    ),
                  ),
                  Text('$days d'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(ctx.tr('common.add'))),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    ref.read(addFoodItemProvider).call(
          name: name,
          expiry: ref.read(clockProvider).now().add(Duration(days: days)),
        );
  }

  Future<void> _addShoppingDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('food.addToList')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: ctx.tr('food.item')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(ctx.tr('common.add'))),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    ref.read(addShoppingItemProvider).call(name);
  }

  Future<void> _editBudgetDialog(
      BuildContext context, WidgetRef ref, Money current) async {
    final controller = TextEditingController(text: '${current.major}');
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('food.budgetTarget')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '\$ '),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(
                  ctx, double.tryParse(controller.text.replaceAll(',', '.'))),
              child: Text(ctx.tr('common.add'))),
        ],
      ),
    );
    if (value == null || value <= 0) return;
    ref.read(foodBudgetProvider.notifier).setTarget(Money.fromMajor(value));
  }

  Future<void> _addRecipeDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final ingredientsController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('food.newRecipe')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: ctx.tr('food.name')),
            ),
            TextField(
              controller: ingredientsController,
              decoration: InputDecoration(
                labelText: ctx.tr('food.ingredients'),
                helperText: ctx.tr('food.ingredientsHint'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr('common.add'))),
        ],
      ),
    );
    if (ok != true) return;
    ref.read(addRecipeProvider).call(
          name: nameController.text,
          ingredients: ingredientsController.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
        );
  }

  Future<void> _editMealDialog(
      BuildContext context, WidgetRef ref, int weekday, String current) async {
    final controller = TextEditingController(text: current);
    final meal = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('food.wd.$weekday')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: ctx.tr('food.mealFor')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(ctx.tr('common.add'))),
        ],
      ),
    );
    if (meal == null) return;
    ref.read(setMealProvider).call(weekday, meal);
  }
}

class _FoodBudgetCard extends StatelessWidget {
  final Money spent;
  final Money target;
  final VoidCallback onEdit;
  const _FoodBudgetCard({
    required this.spent,
    required this.target,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = target.minorUnits <= 0
        ? 0.0
        : (spent.minorUnits / target.minorUnits).clamp(0.0, 1.0).toDouble();
    final over = spent.minorUnits > target.minorUnits;
    final remaining = Money(target.minorUnits - spent.minorUnits).clampToZero();
    return SectionCard(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('food.budget'),
                  style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Text('${spent.format()} / ${target.format()}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              color: over ? LifeColors.financeDanger : LifeColors.finance,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            over
                ? context.tr('food.overBudget')
                : context.trp('food.remaining', {'amount': remaining.format()}),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// At-a-glance pantry freshness: total, expiring soon, expired.
class _PantryOverview extends ConsumerWidget {
  const _PantryOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).now();
    final items = ref.watch(pantryProvider).valueOrNull ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    final soon = items.where((i) => i.isExpiringSoon(now)).length;
    final expired = items.where((i) => i.isExpired(now)).length;
    return SectionCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(context, '🧺', '${items.length}', context.tr('food.inPantry')),
          _stat(context, '⏳', '$soon', context.tr('food.expiringSoon'),
              color: soon > 0 ? LifeColors.goals : null),
          _stat(context, '⚠️', '$expired', context.tr('food.expiredCount'),
              color: expired > 0 ? LifeColors.financeDanger : null),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String emoji, String value, String label,
      {Color? color}) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// A horizontal row of one-tap "add common item" chips.
class _QuickAddRow extends StatelessWidget {
  final List<(String emoji, String nameKey, int? days)> items;
  final void Function(String emoji, String name, int? days) onPick;
  const _QuickAddRow({required this.items, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (emoji, key, days) in items)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: Text(emoji),
                label: Text(context.tr(key)),
                onPressed: () => onPick(emoji, context.tr(key), days),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;
  const _Header({required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        IconButton.filledTonal(onPressed: onAdd, icon: const Icon(Icons.add)),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      );
}

class _PantryTile extends StatelessWidget {
  final FoodItem item;
  final DateTime now;
  const _PantryTile({required this.item, required this.now});

  @override
  Widget build(BuildContext context) {
    final days = item.daysUntilExpiry(now);
    final expired = item.isExpired(now);
    final soon = item.isExpiringSoon(now);
    final color = expired
        ? LifeColors.financeDanger
        : soon
            ? LifeColors.goals
            : LifeColors.finance;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text(item.emoji),
      ),
      title: Text('${item.name}  ×${item.quantity}'),
      trailing: days == null
          ? null
          : Chip(
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
              backgroundColor: color.withValues(alpha: 0.15),
              label: Text(
                expired
                    ? context.tr('food.expired')
                    : days == 0
                        ? context.tr('food.today')
                        : '${days}d',
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }
}

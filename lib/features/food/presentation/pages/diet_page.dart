import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/presentation/providers/diet_providers.dart';
import 'package:lifeos/features/food/presentation/providers/food_providers.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/features/profile/presentation/pages/profile_page.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';
import 'package:lifeos/shared/widgets/motion.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// The built-in dietitian: today's menu fitted to the user's calorie/macro
/// targets, and for each dish — an approximate cost of the ingredients across
/// three brand-free price tiers (fully offline; no retailer is contacted).
class DietPage extends ConsumerWidget {
  const DietPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessment = ref.watch(assessmentProvider);
    final plan = ref.watch(dayPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('diet.title')),
        actions: [
          if (plan != null) ...[
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              tooltip: context.tr('diet.addAllToShopping'),
              onPressed: () {
                final add = ref.read(addShoppingItemProvider);
                for (final m in plan.meals) {
                  for (final ing in m.ingredients) {
                    add.call(context.tr('prod.${ing.productId}'));
                  }
                }
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                      content: Text(context.tr('food.addedToShopping'))));
              },
            ),
            IconButton(
              icon: const Icon(Icons.casino_outlined),
              tooltip: context.tr('diet.shuffle'),
              onPressed: () {
                ref.read(slotSwapProvider.notifier).state = const {};
                ref.read(dietShuffleProvider.notifier).state++;
              },
            ),
          ],
        ],
      ),
      body: AnimatedBackdrop(
        style: BackdropStyle.orbs,
        color: LifeColors.finance,
        child: assessment == null || plan == null
          ? _NoProfile(onOpen: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
              ))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GradientCard(
                  colors: LifeGradients.diet,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('diet.forToday'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.white)),
                      const SizedBox(height: 6),
                      Text(
                        '${context.tr('diet.target')}: '
                        '${assessment.targetKcal} ${context.tr('diet.kcal')} · '
                        '${context.trp('diet.macrosLine', {
                              'p': assessment.proteinG,
                              'f': assessment.fatG,
                              'c': assessment.carbsG,
                            })}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${context.tr('diet.planned')}: '
                        '${plan.total.kcal} ${context.tr('diet.kcal')} · '
                        '${context.trp('diet.macrosLine', {
                              'p': plan.total.proteinG,
                              'f': plan.total.fatG,
                              'c': plan.total.carbsG,
                            })}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Consumer(builder: (context, ref, _) {
                        final eaten = ref.watch(consumedNutritionProvider);
                        final progress = assessment.targetKcal <= 0
                            ? 0.0
                            : (eaten.kcal / assessment.targetKcal)
                                .clamp(0.0, 1.0)
                                .toDouble();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                color: Colors.white,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.trp('diet.eatenLine', {
                                'eaten': eaten.kcal,
                                'target': assessment.targetKcal,
                              }),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const _MacroRings(),
                const SizedBox(height: 12),
                const _RemainingCard(),
                const SizedBox(height: 12),
                const _FoodLogCard(),
                const SizedBox(height: 12),
                const _DayCostCard(),
                const SizedBox(height: 12),
                for (final meal in plan.meals) ...[
                  _MealCard(meal: meal),
                  const SizedBox(height: 10),
                ],
                Text(
                  context.tr('diet.approx'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
      ),
    );
  }
}

/// Protein / carbs / fat consumed vs target, as rings.
class _MacroRings extends ConsumerWidget {
  const _MacroRings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(assessmentProvider);
    if (a == null) return const SizedBox.shrink();
    final eaten = ref.watch(consumedNutritionProvider);
    return SectionCard(
      child: Row(
        children: [
          _ring(context, context.tr('profile.protein'), eaten.proteinG,
              a.proteinG, const Color(0xFFE5484D)),
          _ring(context, context.tr('profile.carbs'), eaten.carbsG, a.carbsG,
              const Color(0xFF3BA7FF)),
          _ring(context, context.tr('profile.fat'), eaten.fatG, a.fatG,
              const Color(0xFFF5A623)),
        ],
      ),
    );
  }

  Widget _ring(BuildContext context, String label, int eaten, int target,
      Color color) {
    final pct = target <= 0 ? 0.0 : (eaten / target).clamp(0.0, 1.0).toDouble();
    return Expanded(
      child: Column(
        children: [
          GradientRing(
            progress: pct,
            size: 60,
            strokeWidth: 6,
            colors: [color, color.withValues(alpha: 0.45)],
            center: Text('${eaten}g',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text('/ ${target}g', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// How much of the target is left today, after everything eaten.
class _RemainingCard extends ConsumerWidget {
  const _RemainingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(assessmentProvider);
    if (a == null) return const SizedBox.shrink();
    final eaten = ref.watch(consumedNutritionProvider);
    int left(int target, int done) => (target - done).clamp(0, 1 << 30);
    final kcalLeft = left(a.targetKcal, eaten.kcal);
    final over = eaten.kcal > a.targetKcal;
    return SectionCard(
      color: (over ? LifeColors.financeDanger : const Color(0xFF2E9E6B))
          .withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('diet.remaining'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            over
                ? context.trp('diet.overBy',
                    {'n': eaten.kcal - a.targetKcal})
                : context.trp('diet.kcalLeft', {'n': kcalLeft}),
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: over ? LifeColors.financeDanger : null),
          ),
          const SizedBox(height: 4),
          Text(
            context.trp('diet.macrosLeft', {
              'p': left(a.proteinG, eaten.proteinG),
              'f': left(a.fatG, eaten.fatG),
              'c': left(a.carbsG, eaten.carbsG),
            }),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// A manual food diary for things eaten beyond the planned menu.
class _FoodLogCard extends ConsumerWidget {
  const _FoodLogCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(manualFoodProvider);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍽️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(context.tr('diet.foodLog'),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _addDialog(context, ref),
              ),
            ],
          ),
          if (log.isEmpty)
            Text(context.tr('diet.foodLogEmpty'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ))
          else
            for (final e in log)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(e.name)),
                    Text('${e.nutrition.kcal} ${context.tr('diet.kcal')}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () =>
                          ref.read(manualFoodProvider.notifier).remove(e.id),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _addDialog(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final kcal = TextEditingController();
    final p = TextEditingController();
    final f = TextEditingController();
    final c = TextEditingController();
    Widget num(TextEditingController ctrl, String label) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: label, isDense: true),
            ),
          ),
        );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('diet.logFood')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: InputDecoration(labelText: ctx.tr('food.name')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: kcal,
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(labelText: ctx.tr('diet.kcal')),
            ),
            const SizedBox(height: 8),
            Row(children: [num(p, 'P'), num(f, 'F'), num(c, 'C')]),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              int v(TextEditingController t) => int.tryParse(t.text) ?? 0;
              ref.read(manualFoodProvider.notifier).add(
                    name.text,
                    NutritionFacts(
                        kcal: v(kcal),
                        proteinG: v(p),
                        fatG: v(f),
                        carbsG: v(c)),
                  );
              Navigator.pop(ctx);
            },
            child: Text(ctx.tr('common.add')),
          ),
        ],
      ),
    );
  }
}

/// Estimated cheapest cost to buy today's whole menu.
class _DayCostCard extends ConsumerWidget {
  const _DayCostCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(dayPlanProvider);
    if (plan == null) return const SizedBox.shrink();
    final cost = ref.watch(mealCostCalculatorProvider);
    var total = 0;
    for (final m in plan.meals) {
      final c = cost.cheapest(m);
      if (c != null) total += c.$2.minorUnits;
    }
    if (total == 0) return const SizedBox.shrink();
    return SectionCard(
      color: LifeColors.finance.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Text('🛒', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(context.tr('diet.dayCost'),
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Text('≈ ${Money(total, currency: 'UAH').format()}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }
}

class _NoProfile extends StatelessWidget {
  final VoidCallback onOpen;
  const _NoProfile({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🥦', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(context.tr('diet.noProfile'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.person_outline),
              label: Text(context.tr('diet.openProfile')),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends ConsumerWidget {
  final MealOption meal;
  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cost = ref.watch(mealCostCalculatorProvider);
    final totals = cost.basketTotals(meal);
    final cheapest = cost.cheapest(meal);
    final isEaten = ref.watch(eatenMealsProvider).contains(meal.id);

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isEaten,
                onChanged: (_) =>
                    ref.read(eatenMealsProvider.notifier).toggle(meal.id),
              ),
              Text(meal.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('diet.slot.${meal.slot.name}'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            )),
                    Text(context.tr(meal.nameKey),
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              if (meal.slot != MealSlot.snack)
                IconButton(
                  icon: const Icon(Icons.swap_horiz, size: 20),
                  tooltip: context.tr('diet.swapMeal'),
                  onPressed: () =>
                      ref.read(slotSwapProvider.notifier).update((m) => {
                            ...m,
                            meal.slot: (m[meal.slot] ?? 0) + 1,
                          }),
                ),
              IconButton(
                icon: const Icon(Icons.add_shopping_cart, size: 20),
                tooltip: context.tr('food.toShopping'),
                onPressed: () {
                  final add = ref.read(addShoppingItemProvider);
                  for (final ing in meal.ingredients) {
                    add.call(context.tr('prod.${ing.productId}'));
                  }
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                        content: Text(context.tr('food.addedToShopping'))));
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${meal.nutrition.kcal} ${context.tr('diet.kcal')} · '
            '${context.trp('diet.macrosLine', {
                  'p': meal.nutrition.proteinG,
                  'f': meal.nutrition.fatG,
                  'c': meal.nutrition.carbsG,
                })}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            meal.ingredients
                .map((i) =>
                    '${context.tr('prod.${i.productId}')} ${i.amount} ${context.tr('unit.${i.unit.name}')}')
                .join(' · '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          if (cheapest != null)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              shape: const Border(),
              title: Text(
                '${context.tr('diet.whereToBuy')} · '
                '${context.trp('diet.fromStore', {
                      'price': cheapest.$2.format(),
                      'store': context.tr('store.${cheapest.$1.id}'),
                    })}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              children: [
                for (final entry in totals.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key == cheapest.$1
                                ? '⭐ ${context.tr('store.${entry.key.id}')} · ${context.tr('diet.cheapest')}'
                                : context.tr('store.${entry.key.id}'),
                          ),
                        ),
                        Text(entry.value.format(),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                const Divider(),
                for (final (productId, quote)
                    in ref.watch(mealCostCalculatorProvider).breakdown(
                          meal,
                          cheapest.$1,
                        ))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${context.tr('prod.$productId')} '
                            '(${quote.packAmount} ${context.tr('unit.${quote.packUnit.name}')})',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Text(quote.price.format(),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
        ],
      ),
    );
  }
}

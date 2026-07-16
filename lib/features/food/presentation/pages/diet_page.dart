import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/food/application/diet_planner.dart';
import 'package:lifeos/features/food/domain/diet_catalog.dart';
import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/domain/medical_diets.dart';
import 'package:lifeos/features/food/domain/recipe_catalog.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';
import 'package:lifeos/features/food/presentation/providers/diet_providers.dart';
import 'package:lifeos/features/food/presentation/providers/food_providers.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/features/profile/presentation/pages/profile_page.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
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
          if (assessment != null)
            IconButton(
              icon: const Icon(Icons.spa_outlined),
              tooltip: context.tr('diet.plansTitle'),
              onPressed: () => _DietPlansSheet.show(context),
            ),
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
                _ChooseDietCard(onTap: () => _DietPlansSheet.show(context)),
                const SizedBox(height: 12),
                const _MacroRings(),
                const SizedBox(height: 12),
                const _RemainingCard(),
                const SizedBox(height: 12),
                const _FoodLogCard(),
                const SizedBox(height: 12),
                const _DayCostCard(),
                const SizedBox(height: 12),
                _MenuEntry(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const MenuPage()),
                  ),
                ),
                const SizedBox(height: 12),
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

/// Prompt to open the diets catalog — "pick a diet to reach your shape".
class _ChooseDietCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ChooseDietCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onTap,
      color: LifeColors.mind.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('diet.chooseTitle'),
                    style: Theme.of(context).textTheme.titleMedium),
                Text(context.tr('diet.chooseSub'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        )),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

/// Popular doctor-backed diets ranked for the user, ideal athletic reference
/// metrics, and today's water + home-exercise guidance — all in one popup.
class _DietPlansSheet extends ConsumerWidget {
  const _DietPlansSheet();

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const _DietPlansSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final a = ref.watch(assessmentProvider);
    if (profile == null || a == null) return const SizedBox.shrink();

    final glasses = (a.waterLiters * 4).round(); // 250 ml per glass
    final ranked = recommendDiets(profile, highWhrRisk: a.whrHighRisk);
    final athleticBodyFat = profile.sex == Sex.male ? '10–15%' : '18–24%';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Text(context.tr('diet.plansTitle'),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),

          // Ideal athletic reference.
          SectionCard(
            color: LifeColors.finance.withValues(alpha: 0.12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏆 ${context.tr('diet.idealTitle')}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _stat(context, context.tr('diet.idealWeight'),
                    '${a.idealWeightKg.toStringAsFixed(1)} kg'),
                _stat(context, context.tr('diet.athleticBodyFat'),
                    athleticBodyFat),
                _stat(context, context.tr('diet.targetKcalRow'),
                    '${a.targetKcal} ${context.tr('diet.kcal')}'),
                _stat(context, context.tr('diet.waterRow'),
                    context.trp('diet.glasses', {'n': glasses})),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Today's home-exercise guidance, tuned to a desk job.
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏠 ${context.tr('diet.homeTitle')}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  context.tr(
                      profile.deskJob ? 'diet.homeDesk' : 'diet.homeActive'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 8),
                _bullet(context, '🌅', context.tr('diet.morning')),
                _bullet(context, '🌆', context.tr('diet.evening')),
                _bullet(context, '🏃', context.tr('diet.cardio')),
                _bullet(context, '🩹', context.tr('diet.injury')),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(context.tr('diet.recommendedTitle'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < ranked.length; i++)
            _DietPlanCard(plan: ranked[i], recommended: i == 0),
          const SizedBox(height: 16),
          _SeasonalVitaminsCard(month: ref.watch(clockProvider).now().month),
          const SizedBox(height: 16),
          const _MedicalDietsSection(),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _bullet(BuildContext context, String emoji, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$emoji  '),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

class _DietPlanCard extends ConsumerWidget {
  final DietPlan plan;
  final bool recommended;
  const _DietPlanCard({required this.plan, required this.recommended});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(selectedDietProvider) == plan.id;
    return SectionCard(
      color: isSelected
          ? LifeColors.finance.withValues(alpha: 0.14)
          : recommended
              ? LifeColors.mind.withValues(alpha: 0.12)
              : null,
      onTap: () => _DietDetailSheet.show(context, plan),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(plan.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(context.tr(plan.nameKey),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              if (isSelected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: LifeColors.finance,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(context.tr('diet.selectedBadge'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                )
              else if (recommended)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: LifeColors.mind,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(context.tr('diet.recommended'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: 6),
          Text(context.tr(plan.summaryKey),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(context.tr('diet.tapForDetails'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  )),
        ],
      ),
    );
  }
}

/// The full breakdown of one diet: how it works, pros, cons and tips.
class _DietDetailSheet {
  static Future<void> show(BuildContext context, DietPlan plan) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (ctx, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            children: [
              Row(
                children: [
                  Text(plan.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(ctx.tr(plan.nameKey),
                        style: Theme.of(ctx).textTheme.headlineSmall),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(ctx.tr(plan.summaryKey),
                  style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Consumer(
                builder: (c, ref, _) {
                  final selected = ref.watch(selectedDietProvider) == plan.id;
                  return SizedBox(
                    width: double.infinity,
                    child: selected
                        ? OutlinedButton.icon(
                            onPressed: () => ref
                                .read(selectedDietProvider.notifier)
                                .select(null),
                            icon: const Icon(Icons.check_circle),
                            label: Text(c.tr('diet.selectedTapToClear')),
                          )
                        : FilledButton.icon(
                            onPressed: () {
                              ref
                                  .read(selectedDietProvider.notifier)
                                  .select(plan.id);
                              ScaffoldMessenger.of(c)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(SnackBar(
                                    content: Text(c.trp('diet.dietChosen', {
                                  'diet': c.tr(plan.nameKey),
                                }))));
                            },
                            icon: const Icon(Icons.restaurant),
                            label: Text(c.tr('diet.selectThis')),
                          ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _heading(ctx, ctx.tr('diet.howTitle')),
              const SizedBox(height: 6),
              Text(ctx.tr(plan.howKey),
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.4)),
              const SizedBox(height: 16),
              _heading(ctx, '📜 ${ctx.tr('diet.history')}'),
              const SizedBox(height: 6),
              Text(ctx.tr(plan.historyKey),
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.4)),
              const SizedBox(height: 16),
              _heading(ctx, '🩺 ${ctx.tr('diet.expert')}'),
              const SizedBox(height: 6),
              Text(ctx.tr(plan.expertKey),
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.4)),
              const SizedBox(height: 16),
              _heading(ctx, '✅ ${ctx.tr('diet.pros')}'),
              const SizedBox(height: 6),
              for (final k in plan.proKeys)
                _bulletRow(ctx, '+', ctx.tr(k), const Color(0xFF2E9E6B)),
              const SizedBox(height: 12),
              _heading(ctx, '⚠️ ${ctx.tr('diet.cons')}'),
              const SizedBox(height: 6),
              for (final k in plan.conKeys)
                _bulletRow(ctx, '−', ctx.tr(k), LifeColors.goals),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LifeColors.health.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heading(ctx, '⛔ ${ctx.tr('diet.contra')}'),
                    const SizedBox(height: 6),
                    Text(ctx.tr(plan.contraKey),
                        style: Theme.of(ctx)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _heading(ctx, '💡 ${ctx.tr('diet.howToStart')}'),
              const SizedBox(height: 6),
              Text(ctx.tr(plan.tipsKey),
                  style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Text(ctx.tr('diet.notAdvice'),
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.outline,
                      )),
            ],
          ),
        ),
      );

  static Widget _heading(BuildContext ctx, String text) => Text(text,
      style: Theme.of(ctx)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w800));

  static Widget _bulletRow(
          BuildContext ctx, String mark, String text, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$mark  ',
                style: TextStyle(color: color, fontWeight: FontWeight.w900)),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

/// Therapeutic ("table") diets — shown for reference, activated only when the
/// user confirms their own doctor prescribed one.
class _MedicalDietsSection extends ConsumerWidget {
  const _MedicalDietsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescribed = ref.watch(prescribedDietsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🩺 ${context.tr('meddiet.title')}',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(context.tr('meddiet.sub'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                )),
        const SizedBox(height: 8),
        for (final d in kMedicalDiets)
          SectionCard(
            onTap: () => _MedicalDietSheet.show(context, d),
            color: prescribed.contains(d.id)
                ? LifeColors.health.withValues(alpha: 0.12)
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Text(d.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr(d.nameKey),
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(context.tr(d.conditionKey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              )),
                    ],
                  ),
                ),
                if (prescribed.contains(d.id))
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: LifeColors.health,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(context.tr('meddiet.prescribed'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
      ],
    );
  }
}

/// One therapeutic diet: condition, what to eat, what to avoid, how to cook,
/// plus the "my doctor prescribed this" opt-in.
class _MedicalDietSheet extends ConsumerWidget {
  final MedicalDiet diet;
  const _MedicalDietSheet(this.diet);

  static Future<void> show(BuildContext context, MedicalDiet diet) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _MedicalDietSheet(diet),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescribed = ref.watch(prescribedDietsProvider).contains(diet.id);
    Widget block(String emoji, String title, String bodyKey) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$emoji $title',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(context.tr(bodyKey),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.4)),
            ],
          ),
        );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Row(
            children: [
              Text(diet.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(context.tr(diet.nameKey),
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(context.tr(diet.conditionKey),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: 16),
          block('✅', context.tr('meddiet.eat'), diet.eatKey),
          block('⛔', context.tr('meddiet.avoid'), diet.avoidKey),
          block('🍳', context.tr('meddiet.cook'), diet.cookKey),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LifeColors.health.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: prescribed,
                  onChanged: (_) =>
                      ref.read(prescribedDietsProvider.notifier).toggle(diet.id),
                  title: Text(context.tr('meddiet.myDoctor')),
                ),
                Text(context.tr('meddiet.disclaimer'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontStyle: FontStyle.italic,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Seasonal vitamin guidance — which vitamins tend to run low each season,
/// with the current season highlighted.
class _SeasonalVitaminsCard extends StatelessWidget {
  final int month;
  const _SeasonalVitaminsCard({required this.month});

  @override
  Widget build(BuildContext context) {
    final current = currentSeasonId(month);
    return SectionCard(
      color: LifeColors.finance.withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💊 ${context.tr('vit.title')}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(context.tr('vit.sub'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  )),
          const SizedBox(height: 10),
          for (final v in kSeasonalVitamins)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${v.emoji}  ', style: const TextStyle(fontSize: 16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(context.tr(v.nameKey),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            if (v.id == current) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: LifeColors.finance,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(context.tr('vit.now'),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ],
                        ),
                        Text(context.tr(v.bodyKey),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

/// Compact entry that opens the full weeks → days → meals menu in one place.
class _MenuEntry extends ConsumerWidget {
  final VoidCallback onTap;
  const _MenuEntry({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dietId = ref.watch(selectedDietProvider);
    final sub = dietId == null
        ? context.tr('menu.sub')
        : context.trp('diet.menuForDiet',
            {'diet': context.tr('diet.plan.$dietId.name')});
    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.restaurant_menu, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('menu.title'),
                    style: Theme.of(context).textTheme.titleMedium),
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        )),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

/// The whole menu in one place: pick a week, then a day, then a meal (which
/// opens its recipe). Adapts to the selected diet.
class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dietId = ref.watch(selectedDietProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('menu.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.orbs,
        color: LifeColors.finance,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (dietId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  context.trp('diet.menuForDiet',
                      {'diet': context.tr('diet.plan.$dietId.name')}),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            Row(
              children: [
                const Icon(Icons.eco, size: 16, color: LifeColors.finance),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(context.tr('menu.seasonalNote'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          )),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _GroceryBudgetEntry(
              onTap: () => _GroceryBudgetSheet.show(context),
            ),
            const SizedBox(height: 12),
            const _WeekSelector(),
            const SizedBox(height: 12),
            const _WeekMenuSection(),
          ],
        ),
      ),
    );
  }
}

/// Compact entry showing the week's food cost vs budget; opens the full
/// budget + shopping-list sheet.
class _GroceryBudgetEntry extends ConsumerWidget {
  final VoidCallback onTap;
  const _GroceryBudgetEntry({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groceries = ref.watch(weeklyGroceriesProvider);
    final budget = ref.watch(weeklyFoodBudgetProvider);
    if (groceries == null) return const SizedBox.shrink();
    final total = groceries.total;
    final over = total.minorUnits > budget;
    final pct = budget <= 0
        ? 1.0
        : (total.minorUnits / budget).clamp(0.0, 1.0).toDouble();
    return SectionCard(
      onTap: onTap,
      color: (over ? LifeColors.financeDanger : LifeColors.finance)
          .withValues(alpha: 0.10),
      child: Row(
        children: [
          const Text('🛒', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('grocery.title'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    color: over ? LifeColors.financeDanger : LifeColors.finance,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${total.format()} / ${Money(budget, currency: 'UAH').format()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

/// Full food-budget + weekly shopping-list popup.
class _GroceryBudgetSheet extends ConsumerWidget {
  const _GroceryBudgetSheet();

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const _GroceryBudgetSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groceries = ref.watch(weeklyGroceriesProvider);
    final budget = ref.watch(weeklyFoodBudgetProvider);
    final spent = ref.watch(weeklyFoodSpendProvider);
    if (groceries == null) return const SizedBox.shrink();
    final total = groceries.total;
    final over = total.minorUnits > budget;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(context.tr('grocery.title'),
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
              TextButton.icon(
                onPressed: () => _editBudget(context, ref, budget),
                icon: const Icon(Icons.edit, size: 18),
                label: Text(context.tr('grocery.editBudget')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Weekly cost vs budget.
          SectionCard(
            color: (over ? LifeColors.financeDanger : LifeColors.finance)
                .withValues(alpha: 0.12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  over
                      ? context.trp('grocery.over', {
                          'amount': Money(total.minorUnits - budget,
                                  currency: 'UAH')
                              .format(),
                        })
                      : context.trp('grocery.within', {
                          'amount': Money(budget - total.minorUnits,
                                  currency: 'UAH')
                              .format(),
                        }),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: over ? LifeColors.financeDanger : LifeColors.finance,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${context.tr('grocery.weekCost')}: ${total.format()} · '
                  '${context.tr('grocery.budget')}: '
                  '${Money(budget, currency: 'UAH').format()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  context.trp('grocery.actual', {'amount': spent.format()}),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.trp('grocery.list', {'n': groceries.lines.length}),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  final add = ref.read(addShoppingItemProvider);
                  for (final l in groceries.lines) {
                    add.call(context.tr('prod.${l.productId}'));
                  }
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                        content: Text(context.tr('food.addedToShopping'))));
                },
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: Text(context.tr('grocery.addAll')),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final l in groceries.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${context.tr('prod.${l.productId}')} · '
                      '${l.packs}×',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text('${context.tr('store.${l.store.id}')} · ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          )),
                  Text(l.cost.format(),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('grocery.total'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(total.format(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editBudget(
      BuildContext context, WidgetRef ref, int current) async {
    final controller =
        TextEditingController(text: (current / 100).round().toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('grocery.editBudget')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: ctx.tr('grocery.weekBudgetLabel'),
            suffixText: '₴',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              final major = int.tryParse(controller.text.trim()) ?? 0;
              Navigator.pop(ctx, major * 100);
            },
            child: Text(ctx.tr('common.save')),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      ref.read(weeklyFoodBudgetProvider.notifier).set(result);
    }
  }
}

/// Four-week selector row.
class _WeekSelector extends ConsumerWidget {
  const _WeekSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(selectedMenuWeekProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var w = 0; w < 4; w++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(context.trp('menu.week', {'n': w + 1})),
                selected: sel == w,
                onSelected: (_) =>
                    ref.read(selectedMenuWeekProvider.notifier).state = w,
              ),
            ),
        ],
      ),
    );
  }
}

/// The selected week's menu as day tabs; each meal opens in a detail popup.
/// Today (week 0, day 0) is interactive; the rest are a read-only preview.
class _WeekMenuSection extends ConsumerWidget {
  const _WeekMenuSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(weekPlanProvider);
    if (week == null || week.isEmpty) return const SizedBox.shrink();
    final weekIdx = ref.watch(selectedMenuWeekProvider);
    final sel = ref.watch(selectedDietDayProvider).clamp(0, week.length - 1);
    final now = ref.watch(clockProvider).now();
    final day = week[sel];
    final isToday = weekIdx == 0 && sel == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: week.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (c, i) => _DayCard(
              date: now.add(Duration(days: weekIdx * 7 + i)),
              isToday: weekIdx == 0 && i == 0,
              selected: sel == i,
              onTap: () =>
                  ref.read(selectedDietDayProvider.notifier).state = i,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _DaySummaryCard(day: day),
        const SizedBox(height: 12),
        for (final meal in day.meals) ...[
          _MealTile(meal: meal, today: isToday),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Accent colour for a meal slot — used as a left bar on the meal card and the
/// summary chips.
Color slotColor(MealSlot slot) => switch (slot) {
      MealSlot.breakfast => const Color(0xFFF5A623),
      MealSlot.lunch => const Color(0xFF2E9E6B),
      MealSlot.dinner => const Color(0xFF3BA7FF),
      MealSlot.snack => const Color(0xFF8E5BFF),
    };

/// A compact date card in the day strip: weekday + date number, highlighted
/// when selected, with a dot on today.
class _DayCard extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool selected;
  final VoidCallback onTap;
  const _DayCard({
    required this.date,
    required this.isToday,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wd = DateFormat.E(Localizations.localeOf(context).languageCode)
        .format(date);
    final fg = selected ? Colors.white : scheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 54,
        decoration: BoxDecoration(
          color: selected
              ? LifeColors.finance
              : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(wd.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white70 : scheme.outline)),
            const SizedBox(height: 2),
            Text('${date.day}',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: fg)),
            const SizedBox(height: 3),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday
                    ? (selected ? Colors.white : LifeColors.finance)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The selected day's calories vs target, macros and estimated cost.
class _DaySummaryCard extends ConsumerWidget {
  final DayPlan day;
  const _DaySummaryCard({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(assessmentProvider);
    final target = (a?.targetKcal ?? day.total.kcal).clamp(1, 1 << 30);
    final pct = (day.total.kcal / target).clamp(0.0, 1.0).toDouble();
    final cost = ref.watch(mealCostCalculatorProvider);
    var costMinor = 0;
    for (final m in day.meals) {
      final c = cost.cheapest(m);
      if (c != null) costMinor += c.$2.minorUnits;
    }
    final t = day.total;
    return SectionCard(
      color: LifeColors.finance.withValues(alpha: 0.10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${t.kcal}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              Text('/ $target ${context.tr('diet.kcal')}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      )),
              const Spacer(),
              if (costMinor > 0)
                Text('≈ ${Money(costMinor, currency: 'UAH').format()}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              color: LifeColors.finance,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _macro(context, context.tr('profile.protein'), t.proteinG,
                  const Color(0xFFE5484D)),
              _macro(context, context.tr('profile.fat'), t.fatG,
                  const Color(0xFFF5A623)),
              _macro(context, context.tr('profile.carbs'), t.carbsG,
                  const Color(0xFF3BA7FF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macro(BuildContext context, String label, int grams, Color color) =>
      Expanded(
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('$label ${grams}g',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}

/// A meal card inside a day tab: slot-coloured accent, dish, cuisine and a
/// calorie badge. Tapping opens the full detail popup.
class _MealTile extends ConsumerWidget {
  final MealOption meal;
  final bool today;
  const _MealTile({required this.meal, required this.today});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eaten = today && ref.watch(eatenMealsProvider).contains(meal.id);
    final accent = slotColor(meal.slot);
    return SectionCard(
      padding: EdgeInsets.zero,
      onTap: () => _MealDetailSheet.show(context, meal, today: today),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                child: Row(
                  children: [
                    Text(meal.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(context.tr('diet.slot.${meal.slot.name}'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: accent,
                                        fontWeight: FontWeight.w700,
                                      )),
                              if (meal.region != null) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.public, size: 11),
                                const SizedBox(width: 2),
                                Text(context.tr(meal.region!),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        )),
                              ],
                            ],
                          ),
                          Text(context.tr(meal.nameKey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    decoration: eaten
                                        ? TextDecoration.lineThrough
                                        : null,
                                  )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${meal.nutrition.kcal}',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: accent)),
                    ),
                    const SizedBox(width: 6),
                    Icon(eaten ? Icons.check_circle : Icons.chevron_right,
                        size: 20,
                        color: eaten ? const Color(0xFF2E9E6B) : null),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single meal's full detail (ingredients, nutrition, cost) in a popup.
class _MealDetailSheet {
  static Future<void> show(BuildContext context, MealOption meal,
          {required bool today}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (ctx, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(ctx.tr('diet.slot.${meal.slot.name}'),
                  style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                        color: Theme.of(ctx).colorScheme.outline,
                      )),
              Text(ctx.tr(meal.nameKey),
                  style: Theme.of(ctx).textTheme.headlineSmall),
              if (meal.region != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.public, size: 16),
                      const SizedBox(width: 6),
                      Text(ctx.tr(meal.region!),
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                color: Theme.of(ctx).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              )),
                    ],
                  ),
                ),
              if (today && meal.slot != MealSlot.snack)
                Consumer(
                  builder: (c, ref, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(slotSwapProvider.notifier).update((m) => {
                              ...m,
                              meal.slot: (m[meal.slot] ?? 0) + 1,
                            });
                        Navigator.of(c).maybePop();
                      },
                      icon: const Icon(Icons.casino_outlined),
                      label: Text(c.tr('diet.otherDish')),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              _MealCard(meal: meal, readOnly: !today),
              _RecipeSection(mealId: meal.id),
            ],
          ),
        ),
      );
}

/// Recipe with selectable cooking methods, numbered timed steps and a
/// "what each ingredient adds" section.
class _RecipeSection extends StatefulWidget {
  final String mealId;
  const _RecipeSection({required this.mealId});

  @override
  State<_RecipeSection> createState() => _RecipeSectionState();
}

class _RecipeSectionState extends State<_RecipeSection> {
  int _method = 0;

  List<String> _lines(BuildContext context, String key) => context
      .tr(key)
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final recipe = recipeFor(widget.mealId);
    if (recipe == null) return const SizedBox.shrink();
    final idx = _method.clamp(0, recipe.methods.length - 1);
    final method = recipe.methods[idx];
    final steps = _lines(context, recipe.stepsKey(method.id));
    final flavor = _lines(context, recipe.flavorKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 28),
        Row(
          children: [
            const Icon(Icons.restaurant_menu, size: 20),
            const SizedBox(width: 8),
            Text(context.tr('recipe.title'),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        if (recipe.methods.length > 1) ...[
          const SizedBox(height: 8),
          Text(context.tr('recipe.chooseMethod'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  )),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < recipe.methods.length; i++)
                ChoiceChip(
                  label: Text(context.tr(recipe.methods[i].labelKey)),
                  selected: idx == i,
                  onSelected: (_) => setState(() => _method = i),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: LifeColors.finance,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(steps[i],
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(height: 1.35))),
              ],
            ),
          ),
        if (flavor.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(context.tr('recipe.flavor'),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          for (final f in flavor)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(child: Text(f)),
                ],
              ),
            ),
        ],
        const SizedBox(height: 12),
        Text(context.tr('recipe.chefNote'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontStyle: FontStyle.italic,
                )),
      ],
    );
  }
}

class _MealCard extends ConsumerWidget {
  final MealOption meal;

  /// Future days are read-only: no eaten checkbox and no per-slot swap (those
  /// act on *today's* plan only).
  final bool readOnly;
  const _MealCard({required this.meal, this.readOnly = false});

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
              if (!readOnly)
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
              if (!readOnly && meal.slot != MealSlot.snack)
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

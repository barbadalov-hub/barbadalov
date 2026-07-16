import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/money/domain/entities/budget.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/features/profile/domain/fitness_calculator.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/features/reports/domain/life_forecast.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// "What will happen if…" — projects weight and savings forward from the
/// current pace, with sliders to explore scenarios.
class ForecastPage extends ConsumerStatefulWidget {
  const ForecastPage({super.key});

  @override
  ConsumerState<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends ConsumerState<ForecastPage> {
  int? _deficit; // kcal/day; null until seeded from the assessment
  double? _monthlySave; // major currency; null until seeded from the budget

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(assessmentProvider);
    final profile = ref.watch(profileProvider);
    final budget = ref.watch(currentBudgetProvider);
    final now = ref.watch(clockProvider).now();
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('forecast.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: LifeColors.mind,
        child: (a == null || profile == null)
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(context.tr('diet.noProfile'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              )
            : _body(context, a, profile.weightKg, budget, now, lang),
      ),
    );
  }

  Widget _body(BuildContext context, FitnessAssessment a, double currentKg,
      Budget budget, DateTime now, String lang) {
    final defaultDeficit = (a.tdee - a.targetKcal).clamp(0, 1500);
    final deficit = _deficit ?? defaultDeficit;
    final net = budget.income.major - budget.expenses.major;
    final monthlySave = _monthlySave ?? (net > 0 ? net : 0.0);

    final idealKg = a.idealWeightKg;
    final in3mo = projectWeightKg(currentKg: currentKg, deficit: deficit, days: 90);
    final daysToIdeal =
        daysToWeight(currentKg: currentKg, targetKg: idealKg, deficit: deficit);
    final idealDate = daysToIdeal == null
        ? null
        : DateFormat.yMMM(lang).format(now.add(Duration(days: daysToIdeal)));

    final in6 = projectSavings(monthlyNet: monthlySave, months: 6);
    final in12 = projectSavings(monthlyNet: monthlySave, months: 12);

    String kg(double v) => '${v.toStringAsFixed(1)} kg';
    String money(double v) => Money.fromMajor(v.round()).format();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(context.tr('forecast.intro'),
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),

        // Weight scenario.
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('⚖️ ${context.tr('forecast.weight')}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                context.trp('forecast.weightIn3', {
                  'now': kg(currentKg),
                  'later': kg(in3mo),
                }),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                idealDate == null
                    ? context.tr('forecast.weightStuck')
                    : context.trp('forecast.weightReach',
                        {'kg': kg(idealKg), 'date': idealDate}),
                style: TextStyle(
                    color: idealDate == null
                        ? Theme.of(context).colorScheme.outline
                        : LifeColors.finance,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(context.trp('forecast.deficit', {'n': deficit}),
                  style: Theme.of(context).textTheme.bodySmall),
              Slider(
                value: deficit.toDouble(),
                min: 0,
                max: 1000,
                divisions: 20,
                label: '$deficit',
                onChanged: (v) => setState(() => _deficit = v.round()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Savings scenario.
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💰 ${context.tr('forecast.savings')}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                context.trp('forecast.saveIn', {
                  'six': money(in6),
                  'year': money(in12),
                }),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(context.trp('forecast.perMonth', {'amount': money(monthlySave)}),
                  style: Theme.of(context).textTheme.bodySmall),
              Slider(
                value: monthlySave.clamp(0, _saveMax(net)),
                min: 0,
                max: _saveMax(net),
                divisions: 20,
                label: money(monthlySave),
                onChanged: (v) => setState(() => _monthlySave = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(context.tr('forecast.disclaimer'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                )),
      ],
    );
  }

  double _saveMax(double net) {
    final byNet = net > 0 ? net * 3 : 0.0;
    return byNet < 20000 ? 20000 : byNet;
  }
}

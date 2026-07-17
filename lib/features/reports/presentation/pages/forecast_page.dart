import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/goals/application/forecast_goal.dart';
import 'package:lifeos/features/goals/domain/entities/goal.dart';
import 'package:lifeos/features/goals/presentation/providers/goal_providers.dart';
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
/// current pace, with sliders to explore scenarios. The savings scenario is
/// tied to the user's real goals, so it answers "when will I reach *this*?".
class ForecastPage extends ConsumerStatefulWidget {
  const ForecastPage({super.key});

  @override
  ConsumerState<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends ConsumerState<ForecastPage> {
  int? _kcalMagnitude; // daily kcal deficit OR surplus size; null until seeded
  double? _monthlySave; // major currency; null until seeded from the budget

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(assessmentProvider);
    final profile = ref.watch(profileProvider);
    final budget = ref.watch(currentBudgetProvider);
    final goals = ref.watch(goalsProvider).valueOrNull ?? const <Goal>[];
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
            : _body(context, a, profile.weightKg, budget, goals, now, lang),
      ),
    );
  }

  Widget _body(BuildContext context, FitnessAssessment a, double currentKg,
      Budget budget, List<Goal> goals, DateTime now, String lang) {
    final net = budget.available.major;
    final monthlySave = _monthlySave ?? (net > 0 ? net : 0.0);

    final idealKg = a.idealWeightKg;
    // Which way the ideal weight lies decides deficit (lose) vs surplus (gain).
    final gaining = idealKg - currentKg > 0.5;
    final magnitudeDefault = (a.tdee - a.targetKcal).abs().clamp(0, 1500);
    final magnitude = _kcalMagnitude ?? magnitudeDefault;
    final dailyDelta = gaining ? magnitude : -magnitude;

    final in3mo =
        projectWeightKg(currentKg: currentKg, dailyDelta: dailyDelta, days: 90);
    final daysToIdeal = daysToWeight(
        currentKg: currentKg, targetKg: idealKg, dailyDelta: dailyDelta);
    final idealDate = (daysToIdeal == null || daysToIdeal == 0)
        ? null
        : DateFormat.yMMM(lang).format(now.add(Duration(days: daysToIdeal)));

    final activeGoals = goals.where((g) => !g.isComplete).toList();

    String kg(double v) =>
        context.trp('forecast.kg', {'n': v.toStringAsFixed(1)});
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
              Builder(builder: (context) {
                final String text;
                final Color color;
                if (daysToIdeal == 0) {
                  text = context.tr('forecast.weightAtIdeal');
                  color = LifeColors.finance;
                } else if (idealDate != null) {
                  text = context.trp('forecast.weightReach',
                      {'kg': kg(idealKg), 'date': idealDate});
                  color = LifeColors.finance;
                } else {
                  text = context.tr(gaining
                      ? 'forecast.weightStuckGain'
                      : 'forecast.weightStuck');
                  color = Theme.of(context).colorScheme.outline;
                }
                return Text(text,
                    style: TextStyle(color: color, fontWeight: FontWeight.w600));
              }),
              const SizedBox(height: 8),
              Text(
                  context.trp(gaining ? 'forecast.surplus' : 'forecast.deficit',
                      {'n': magnitude}),
                  style: Theme.of(context).textTheme.bodySmall),
              Slider(
                value: magnitude.toDouble(),
                min: 0,
                max: 1000,
                divisions: 20,
                label: '$magnitude',
                onChanged: (v) => setState(() => _kcalMagnitude = v.round()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Savings scenario — tied to real goals.
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💰 ${context.tr('forecast.savings')}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                  context.trp('forecast.perMonth', {'amount': money(monthlySave)}),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Slider(
                value: monthlySave.clamp(0, _saveMax(net)),
                min: 0,
                max: _saveMax(net),
                divisions: 20,
                label: money(monthlySave),
                onChanged: (v) => setState(() => _monthlySave = v),
              ),
              const SizedBox(height: 4),
              if (activeGoals.isEmpty)
                Text(context.tr('forecast.noGoals'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline))
              else ...[
                Text(context.tr('forecast.goalsHeader'),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                for (final g in activeGoals)
                  _GoalRow(
                    goal: g,
                    monthlySave: monthlySave,
                    now: now,
                    lang: lang,
                  ),
              ],
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

/// One goal's projected outcome at the slider's monthly-saving rate.
class _GoalRow extends StatelessWidget {
  final Goal goal;
  final double monthlySave;
  final DateTime now;
  final String lang;
  const _GoalRow({
    required this.goal,
    required this.monthlySave,
    required this.now,
    required this.lang,
  });

  static const _warning = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    final monthlyNet =
        Money.fromMajor(monthlySave.round(), currency: goal.remaining.currency);
    final f = const ForecastGoal().call(goal, monthlyNet: monthlyNet, now: now);

    final String status;
    final Color color;
    if (f.projectedDate == null) {
      status = context.tr('forecast.goalStalled');
      color = Theme.of(context).colorScheme.outline;
    } else {
      final date = DateFormat.yMMM(lang).format(f.projectedDate!);
      final base = context.trp('forecast.goalBy', {'date': date});
      if (goal.targetDate == null) {
        status = base;
        color = LifeColors.finance;
      } else if (f.onTrackForTargetDate) {
        status = '$base · ${context.tr('forecast.goalOnTrack')}';
        color = LifeColors.finance;
      } else {
        final need = f.requiredMonthly?.format() ?? '';
        status =
            '$base · ${context.trp('forecast.goalBehind', {'amount': need})}';
        color = _warning;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(goal.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(status,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

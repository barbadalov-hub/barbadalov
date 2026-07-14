import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:lifeos/features/health/presentation/providers/health_goals_provider.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/features/health/presentation/providers/vitals_provider.dart';
import 'package:lifeos/features/health/presentation/pages/workouts_page.dart';
import 'package:lifeos/features/health/domain/entities/health_day.dart';
import 'package:lifeos/features/health/presentation/widgets/drink_sheet.dart';
import 'package:lifeos/features/health/presentation/widgets/health_charts.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/motion.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

class HealthPage extends ConsumerWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(todayHealthProvider);
    final score = ref.watch(healthScoreProvider);
    final goals = ref.watch(healthGoalsProvider);
    final log = ref.read(logHealthProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('nav.health')),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: context.tr('health.editGoals'),
            onPressed: () => _goalsDialog(context, ref, goals),
          ),
          IconButton(
            icon: const Icon(Icons.bluetooth),
            tooltip: context.tr('health.connectDevice'),
            onPressed: () => _deviceDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.watch_outlined),
            tooltip: context.tr('health.syncDevice'),
            onPressed: () async {
              final sync = ref.read(syncDeviceHealthProvider);
              final snap = await sync.call();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(context.trp('health.synced', {
                    'name': sync.sourceName,
                    'steps': snap.steps,
                    'sleep': snap.sleepHours.toStringAsFixed(1),
                  })),
                ));
              }
            },
          ),
        ],
      ),
      body: AnimatedBackdrop(
        style: BackdropStyle.pulse,
        color: LifeColors.health,
        child: health.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (day) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              color: LifeColors.health.withValues(alpha: 0.12),
              child: Row(
                children: [
                  Text('$score',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('${context.tr('health.scoreToday')}\n'
                        '${context.tr('health.scoreSubtitle')}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Ring(
                  label: context.tr('health.water'),
                  value: day.waterMl.toDouble(),
                  goal: (goals.water * HealthDay.mlPerGlass).toDouble(),
                  unit: context.tr('drink.ml'),
                  color: const Color(0xFF3BA7FF),
                ),
                _Ring(
                  label: context.tr('health.steps'),
                  value: day.steps.toDouble(),
                  goal: goals.steps.toDouble(),
                  unit: '',
                  color: LifeColors.finance,
                ),
                _Ring(
                  label: context.tr('health.sleep'),
                  value: day.sleepHours,
                  goal: goals.sleep,
                  unit: 'h',
                  color: LifeColors.mind,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _StreaksCard(),
            const SizedBox(height: 12),
            const _WeekSummaryCard(),
            const SizedBox(height: 20),
            Text(context.tr('health.log'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Text('💧'),
                  label: Text(context.tr('health.addWater')),
                  onPressed: () => DrinkSheet.show(context),
                ),
                ActionChip(
                  avatar: const Text('👟'),
                  label: Text(context.tr('health.addSteps')),
                  onPressed: () => log.setSteps(day.steps + 1000),
                ),
                ActionChip(
                  avatar: const Text('😴'),
                  label: Text(context.tr('health.logSleep')),
                  onPressed: () => log.logSleep(8),
                ),
                ActionChip(
                  avatar: const Text('🎧'),
                  label: Text(context.tr('health.addListening')),
                  onPressed: () => log.addListening(30),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Text('⚖️', style: TextStyle(fontSize: 22)),
              title: Text(context.tr('health.weight')),
              subtitle: Text(context.tr('health.weightTapHint'),
                  style: Theme.of(context).textTheme.bodySmall),
              trailing: Text(
                day.weightKg == null
                    ? '—'
                    : '${day.weightKg!.toStringAsFixed(1)} kg',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () => _weightDialog(context, ref, day.weightKg),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Text('💓', style: TextStyle(fontSize: 22)),
              title: Text(context.tr('health.heartRate')),
              trailing: Text(
                day.heartRate == null
                    ? '—'
                    : '${day.heartRate} ${context.tr('health.bpm')}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            const _VitalsCard(),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Text('🎧', style: TextStyle(fontSize: 22)),
              title: Text(context.tr('health.headphones')),
              subtitle: day.listeningMinutes >= 120
                  ? Text(context.tr('health.listeningWarn'),
                      style: const TextStyle(color: LifeColors.goals))
                  : null,
              trailing: Text(
                '${day.listeningMinutes} ${context.tr('health.min')}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 4),
            Text(context.tr('health.stress'),
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text('$i'),
                      selected: day.stress == i,
                      onSelected: (_) => log.logStress(i),
                    ),
                  ),
                const SizedBox(width: 6),
                Text(context.tr('health.stressHint'),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              padding: const EdgeInsets.all(14),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const WorkoutsPage()),
              ),
              child: Row(
                children: [
                  const Text('💪', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('wo.title'),
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(context.tr('wo.subtitle'),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.outline,
                                )),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const WeightTrendCard(),
            const StepsWeekCard(),
            const WaterWeekCard(),
            const SleepWeekCard(),
            const SizedBox(height: 12),
            Text(
              context.tr('health.deviceHint'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  /// Pick which wearable/platform to sync from. Real pairing (HealthKit /
  /// Google Fit) activates on a phone build; the choice is persisted either way.
  Future<void> _deviceDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(selectedDeviceProvider);
    await showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(ctx.tr('health.connectDevice')),
        children: [
          for (final name in SelectedDeviceController.options)
            SimpleDialogOption(
              onPressed: () {
                ref.read(selectedDeviceProvider.notifier).select(name);
                Navigator.pop(ctx);
              },
              child: Row(
                children: [
                  Icon(
                    name == current
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(name),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Text(
              ctx.tr('health.deviceNote'),
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// Log today's weight. If a profile exists, its weight is synced too, so the
  /// dietitian's targets recalibrate automatically.
  Future<void> _weightDialog(
    BuildContext context,
    WidgetRef ref,
    double? current,
  ) async {
    final controller = TextEditingController(
      text: current == null ? '' : current.toStringAsFixed(1),
    );
    final kg = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('health.setWeight')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: ctx.tr('profile.weight'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(
                ctx, double.tryParse(controller.text.replaceAll(',', '.'))),
            child: Text(ctx.tr('common.save')),
          ),
        ],
      ),
    );
    if (kg == null || kg <= 0 || kg > 400) return;

    ref.read(logHealthProvider).logWeight(kg);
    final profile = ref.read(profileProvider);
    if (profile != null) {
      ref.read(profileProvider.notifier).save(profile.withWeight(kg));
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(context.tr(
              profile != null ? 'health.weightSynced' : 'health.weightSaved')),
        ));
    }
  }

  /// Edit the daily step/water/sleep goals.
  Future<void> _goalsDialog(
      BuildContext context, WidgetRef ref, HealthGoalSet current) async {
    final steps = TextEditingController(text: '${current.steps}');
    final water = TextEditingController(text: '${current.water}');
    final sleep = TextEditingController(
        text: current.sleep == current.sleep.roundToDouble()
            ? '${current.sleep.round()}'
            : current.sleep.toString());
    Widget field(TextEditingController c, String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: TextField(
            controller: c,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
            ],
            decoration:
                InputDecoration(labelText: label, border: const OutlineInputBorder()),
          ),
        );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('health.editGoals')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            field(steps, ctx.tr('health.steps')),
            field(water, ctx.tr('health.glasses')),
            field(sleep, '${ctx.tr('health.sleep')} (h)'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              double d(String s) =>
                  double.tryParse(s.replaceAll(',', '.')) ?? 0;
              final next = HealthGoalSet(
                steps: d(steps.text).round().clamp(1000, 100000),
                water: d(water.text).round().clamp(1, 30),
                sleep: d(sleep.text).clamp(3, 14),
              );
              ref.read(healthGoalsProvider.notifier).save(next);
              Navigator.pop(ctx);
            },
            child: Text(ctx.tr('common.save')),
          ),
        ],
      ),
    );
  }
}

/// Step & hydration goal streaks — light gamification.
class _StreaksCard extends ConsumerWidget {
  const _StreaksCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(stepStreakProvider);
    final water = ref.watch(hydrationStreakProvider);
    if (steps == 0 && water == 0) return const SizedBox.shrink();
    return SectionCard(
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                if (steps > 0)
                  Text('👟 ${context.trp('health.stepStreak', {'n': steps})}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                if (water > 0)
                  Text('💧 ${context.trp('health.waterStreak', {'n': water})}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A 7-day rollup: average water/steps/sleep and how many days hit each goal.
class _WeekSummaryCard extends ConsumerWidget {
  const _WeekSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(weeklyHealthProvider);
    if (!s.hasData) return const SizedBox.shrink();
    final outline = Theme.of(context).colorScheme.outline;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('health.week'),
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            context.trp('health.weekAvg', {
              'steps': s.avgSteps,
              'water': s.avgWater.toStringAsFixed(1),
              'sleep': s.avgSleep.toStringAsFixed(1),
            }),
          ),
          const SizedBox(height: 4),
          Text(
            context.trp('health.weekGoals', {
              'steps': s.daysStepGoal,
              'water': s.daysWaterGoal,
              'sleep': s.daysSleepGoal,
              'n': s.daysLogged,
            }),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: outline),
          ),
        ],
      ),
    );
  }
}

/// Manual blood-pressure + resting-pulse log with a systolic trend.
class _VitalsCard extends ConsumerWidget {
  const _VitalsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(vitalsProvider);
    final latest = log.isNotEmpty ? log.last : null;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🩺', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(context.tr('vitals.title'),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _logDialog(context, ref, latest),
              ),
            ],
          ),
          if (latest == null)
            Text(context.tr('vitals.empty'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ))
          else ...[
            Row(
              children: [
                Text('${latest.systolic}/${latest.diastolic}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
                Text('mmHg · ${latest.pulse} ${context.tr('health.bpm')}',
                    style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Text(context.tr(latest.bandKey),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _bandColor(latest.bandKey))),
              ],
            ),
            if (log.length >= 2) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SystolicSparkline(
                      [for (final v in log) v.systolic.toDouble()]),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Color _bandColor(String key) => switch (key) {
        'vitals.normal' => const Color(0xFF2E9E6B),
        'vitals.elevated' => const Color(0xFFF5A623),
        _ => const Color(0xFFE5484D),
      };

  Future<void> _logDialog(
      BuildContext context, WidgetRef ref, VitalsEntry? last) async {
    final sys = TextEditingController(text: last == null ? '' : '${last.systolic}');
    final dia =
        TextEditingController(text: last == null ? '' : '${last.diastolic}');
    final pul = TextEditingController(text: last == null ? '' : '${last.pulse}');
    Widget f(TextEditingController c, String label) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextField(
              controller: c,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: label, isDense: true),
            ),
          ),
        );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('vitals.log')),
        content: Row(children: [
          f(sys, ctx.tr('vitals.sys')),
          f(dia, ctx.tr('vitals.dia')),
          f(pul, ctx.tr('vitals.pulse')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
            onPressed: () {
              final s = int.tryParse(sys.text) ?? 0;
              final d = int.tryParse(dia.text) ?? 0;
              final p = int.tryParse(pul.text) ?? 0;
              if (s > 0 && d > 0) {
                ref.read(vitalsProvider.notifier).log(VitalsEntry(
                    date: DateTime.now(), systolic: s, diastolic: d, pulse: p));
              }
              Navigator.pop(ctx);
            },
            child: Text(ctx.tr('common.save')),
          ),
        ],
      ),
    );
  }
}

class _SystolicSparkline extends CustomPainter {
  final List<double> values;
  _SystolicSparkline(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    var min = values.first;
    var max = values.first;
    for (final v in values) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    final range = (max - min).abs() < 1 ? 1.0 : max - min;
    final dx = size.width / (values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = dx * i;
      final y = size.height - ((values[i] - min) / range) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFE5484D),
    );
  }

  @override
  bool shouldRepaint(covariant _SystolicSparkline old) => old.values != values;
}

class _Ring extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color color;

  const _Ring({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0).toDouble();
    final display =
        value == value.roundToDouble() ? value.toInt().toString() : '$value';
    return Expanded(
      child: Column(
        children: [
          GradientRing(
            progress: pct,
            size: 70,
            strokeWidth: 7,
            colors: [color, color.withValues(alpha: 0.45)],
            center: Text('${(pct * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text('$display${unit.isEmpty ? '' : ' $unit'}',
              style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

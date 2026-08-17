import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:lifeos/features/health/domain/daily_motivation.dart';
import 'package:lifeos/features/health/presentation/providers/health_goals_provider.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/features/health/presentation/providers/vitals_provider.dart';
import 'package:lifeos/features/health/presentation/pages/workouts_page.dart';
import 'package:lifeos/features/health/domain/entities/health_day.dart';
import 'package:lifeos/features/health/presentation/widgets/drink_sheet.dart';
import 'package:lifeos/features/health/presentation/widgets/health_charts.dart';
import 'package:lifeos/features/food/presentation/pages/diet_page.dart';
import 'package:lifeos/features/food/presentation/pages/food_page.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';
import 'package:lifeos/features/reminders/domain/entities/reminder.dart';
import 'package:lifeos/features/reminders/presentation/pages/reminders_page.dart';
import 'package:lifeos/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/features/wellness/presentation/pages/wellness_page.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/features/rooms/domain/life_room.dart';
import 'package:lifeos/features/rooms/presentation/widgets/room_scaffold.dart';
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

    final room = roomById(RoomId.body);
    final accent = room.colorFor(Theme.of(context).brightness);
    final day = health.valueOrNull;

    return RoomScaffold(
      room: room,
      title: context.tr('nav.health'),
      appBarActions: [
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
      hero: day == null
          ? null
          : RoomHero(
              label: context.tr('health.scoreToday'),
              value: '$score',
              accent: accent,
              progress: score / 100,
              caption: context.tr('health.scoreSubtitle'),
            ),
      voice: _voice(context, day, goals),
      tools: [
        // The room owns the whole body domain — food and cycle used to sit in
        // the More hub, far from the numbers they explain.
        RoomTool(
          icon: Icons.restaurant_outlined,
          label: context.tr('diet.title'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const DietPage()),
          ),
        ),
        RoomTool(
          icon: Icons.kitchen_outlined,
          label: context.tr('more.food'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const FoodPage()),
          ),
        ),
        RoomTool(
          icon: Icons.spa_outlined,
          label: context.tr(ref.watch(profileProvider)?.sex == Sex.female
              ? 'cycle.title'
              : 'wellness.title'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const WellnessPage()),
          ),
        ),
        RoomTool(
          icon: Icons.monitor_heart_outlined,
          label: context.tr('health.metrics'),
          onTap: () => _MetricsSheet.show(context),
        ),
        RoomTool(
          icon: Icons.show_chart,
          label: context.tr('health.trends'),
          onTap: () => _TrendsSheet.show(context),
        ),
        RoomTool(
          icon: Icons.nightlight_outlined,
          label: context.tr('sleep.tipsTitle'),
          onTap: () => _SleepTipsSheet.show(context),
        ),
        RoomTool(
          icon: Icons.fitness_center,
          label: context.tr('wo.title'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const WorkoutsPage()),
          ),
        ),
      ],
      children: day == null
          ? [
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            ]
          : [
            // One accent, three tones. These rings used to be blue, the money
            // room's green and the mind room's purple — three colours that
            // belong to other parts of the app, shouting on one screen. Depth
            // now carries the difference instead of hue.
            Row(
              children: [
                _Ring(
                  label: context.tr('health.water'),
                  value: day.waterMl.toDouble(),
                  goal: (goals.water * HealthDay.mlPerGlass).toDouble(),
                  unit: context.tr('drink.ml'),
                  color: accent,
                ),
                _Ring(
                  label: context.tr('health.steps'),
                  value: day.steps.toDouble(),
                  goal: goals.steps.toDouble(),
                  unit: '',
                  color: accent,
                  tone: 0.22,
                ),
                _Ring(
                  label: context.tr('health.sleep'),
                  value: day.sleepHours,
                  goal: goals.sleep,
                  unit: context.tr('unit.hoursShort'),
                  color: accent,
                  tone: 0.44,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _DayLineCard(),
            const SizedBox(height: 14),
            const _CareShelf(),
            const SizedBox(height: 14),
            const _StreaksCard(),
            const SizedBox(height: 16),
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
            // The old hub grid listed diet, food and wellness — they are the
            // room's tool shelf now, so keeping it would show them twice.
            const SizedBox(height: 12),
            Text(
              context.tr('health.deviceHint'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
    );
  }

  /// One sentence about the body: the metric furthest from its goal, so the
  /// room says what to do rather than restating the rings.
  String _voice(BuildContext context, HealthDay? day, HealthGoalSet goals) {
    // An untouched day arrives as a row of zeroes rather than as null, and
    // scolding someone for "8000 steps short" before they have logged anything
    // reads as an accusation. Nothing recorded means nothing to judge yet.
    final blank = day == null ||
        (day.steps == 0 && day.sleepHours == 0 && day.waterMl == 0);
    if (blank) return context.tr('health.voiceNoData');
    if (day.sleepHours > 0 && day.sleepHours < goals.sleep - 0.75) {
      return context.trp('health.voiceSleep', {
        'h': day.sleepHours.toStringAsFixed(1),
      });
    }
    if (day.steps < goals.steps * 0.6) {
      return context.trp('health.voiceSteps', {
        'left': goals.steps - day.steps,
      });
    }
    if (day.waterMl < goals.water * HealthDay.mlPerGlass * 0.6) {
      return context.tr('health.voiceWater');
    }
    return context.tr('health.voiceGood');
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

/// Compact entry card that opens a grouped detail popup, keeping the main
/// Health screen short (same pattern as Money's analytics entry).
/// A compact grid that gathers every health-related area into one place, so the
/// Health tab is the single hub for diet, food, mind, mood and wellness instead
class _MetricsSheet extends ConsumerWidget {
  const _MetricsSheet();

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const _MetricsSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(todayHealthProvider).valueOrNull;
    final log = ref.read(logHealthProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Text(context.tr('health.metrics'),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Text('⚖️', style: TextStyle(fontSize: 22)),
            title: Text(context.tr('health.weight')),
            subtitle: Text(context.tr('health.weightTapHint'),
                style: Theme.of(context).textTheme.bodySmall),
            trailing: Text(
              day?.weightKg == null
                  ? '—'
                  : '${day!.weightKg!.toStringAsFixed(1)} kg',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () => _weightDialog(context, ref, day?.weightKg),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Text('💓', style: TextStyle(fontSize: 22)),
            title: Text(context.tr('health.heartRate')),
            trailing: Text(
              day?.heartRate == null
                  ? '—'
                  : '${day!.heartRate} ${context.tr('health.bpm')}',
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
            subtitle: (day?.listeningMinutes ?? 0) >= 120
                ? Text(context.tr('health.listeningWarn'),
                    style: const TextStyle(color: LifeColors.goals))
                : null,
            trailing: Text(
              '${day?.listeningMinutes ?? 0} ${context.tr('health.min')}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(context.tr('health.stress'),
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          // Five chips plus the hint are 0.6px too wide for a 360px phone, and
          // a Row has nowhere to put that; Wrap moves the hint to its own line.
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                ChoiceChip(
                  label: Text('$i'),
                  selected: day?.stress == i,
                  onSelected: (_) => log.logStress(i),
                ),
              Text(context.tr('health.stressHint'),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
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
}

/// "Trends" popup: the week summary plus the four trend charts (weight, steps,
/// water, sleep).
class _TrendsSheet extends StatelessWidget {
  const _TrendsSheet();

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const _TrendsSheet(),
      );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(context.tr('health.trends'),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const _WeekSummaryCard(),
          const SizedBox(height: 12),
          const WeightTrendCard(),
          const StepsWeekCard(),
          const WaterWeekCard(),
          const SleepWeekCard(),
        ],
      ),
    );
  }
}

/// "Healthy sleep" popup: pre-sleep exercises + evening-nutrition advice.
/// Static, curated guidance (no tracking) so it works on every platform.
class _SleepTipsSheet extends StatelessWidget {
  const _SleepTipsSheet();

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const _SleepTipsSheet(),
      );

  static const _exercises = ['sleep.ex1', 'sleep.ex2', 'sleep.ex3', 'sleep.ex4'];
  static const _nutrition = ['sleep.nu1', 'sleep.nu2', 'sleep.nu3', 'sleep.nu4'];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Text(context.tr('sleep.tipsTitle'),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(context.tr('sleep.tipsIntro'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  )),
          const SizedBox(height: 16),
          _section(context, '🧘', context.tr('sleep.exercises'), _exercises),
          const SizedBox(height: 16),
          _section(context, '🍽️', context.tr('sleep.nutrition'), _nutrition),
        ],
      ),
    );
  }

  Widget _section(
      BuildContext context, String emoji, String title, List<String> keys) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
          ],
        ),
        const SizedBox(height: 8),
        for (final k in keys)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text(context.tr(k))),
              ],
            ),
          ),
      ],
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
        'vitals.normal' => LifeColors.positive,
        'vitals.elevated' => LifeColors.warning,
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

/// The day's line: a different sentence for the morning, the middle of the day
/// and the evening, and a different one again tomorrow.
///
/// Kept visually apart from the room's voice above it on purpose — that line
/// tells you what to do about your own numbers, this one is not about your
/// numbers at all. Same weight for both would make each sound like the other.
class _DayLineCard extends ConsumerWidget {
  const _DayLineCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final now = ref.watch(clockProvider).now();
    final part = DailyMotivation.partOf(now.hour);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('motiv.part.${part.name}').toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w600,
              color: scheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(DailyMotivation.keyFor(now, part)),
            style: TextStyle(
              // Serif, like the rooms' voice: it marks a sentence meant to be
              // read rather than scanned.
              fontFamily: 'serif',
              fontSize: 16,
              height: 1.4,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// One-tap care reminders. Tapping a chip arms a real OS notification and
/// tapping it again takes it away — no form, no time picker, because the whole
/// point is that drinking water should not need to be configured.
class _CareShelf extends ConsumerWidget {
  const _CareShelf();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final accent = roomById(RoomId.body).colorFor(Theme.of(context).brightness);
    final reminders = ref.watch(remindersProvider);
    final armed = {
      for (final r in reminders)
        if (r.enabled) r.kind: r,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(context.tr('care.title'),
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis),
            ),
            IconButton(
              icon: const Icon(Icons.tune, size: 20),
              tooltip: context.tr('reminder.title'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const RemindersPage()),
              ),
            ),
          ],
        ),
        Text(
          context.tr('care.sub'),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.outline),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in ReminderKind.care)
              _CareChip(
                // Named so a test can reach this chip rather than the first
                // widget that happens to say "Water" — the rings say it too.
                key: ValueKey('care.${kind.name}'),
                kind: kind,
                armed: armed[kind],
                accent: accent,
                onTap: () =>
                    ref.read(remindersProvider.notifier).toggleKind(kind),
              ),
          ],
        ),
      ],
    );
  }
}

class _CareChip extends StatelessWidget {
  final ReminderKind kind;

  /// The armed reminder, or null when this care is off.
  final Reminder? armed;
  final Color accent;
  final VoidCallback onTap;

  const _CareChip({
    required this.kind,
    required this.armed,
    required this.accent,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = armed != null;
    return Material(
      color: on
          ? Color.lerp(accent, scheme.surfaceContainerLowest, 0.86)
          : scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: on ? accent.withValues(alpha: 0.5) : scheme.outlineVariant,
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(kind.emoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    context.tr(kind.shortKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 3),
              Text(
                // Off chips advertise what turning them on would do, so the
                // shelf reads as a menu rather than a row of mystery switches.
                on ? armed!.timeLabel : _defaultLabel(context),
                style: TextStyle(
                  fontSize: 11,
                  color: on ? accent : scheme.outline,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _defaultLabel(BuildContext context) {
    if (kind.every <= 0) {
      return '${kind.defaultHour.toString().padLeft(2, '0')}:'
          '${kind.defaultMinute.toString().padLeft(2, '0')}';
    }
    return context.trp('care.every', {'h': (kind.every / 60).toStringAsFixed(
        kind.every % 60 == 0 ? 0 : 1)});
  }
}

class _Ring extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color color;

  /// How far this ring is pulled towards the page, 0 = the full accent. Lets
  /// three rings read as three things without three different hues.
  final double tone;

  const _Ring({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
    this.tone = 0,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shade = Color.lerp(color, scheme.surface, tone)!;
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
            colors: [shade, shade.withValues(alpha: 0.45)],
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

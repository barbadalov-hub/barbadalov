import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/health/domain/entities/health_day.dart';
import 'package:lifeos/features/health/presentation/providers/health_goals_provider.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// Weight trend line over the logged history, with the profile's BMI-22
/// reference weight as a dashed guide (the classic fitness-app chart).
class WeightTrendCard extends ConsumerWidget {
  const WeightTrendCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(weightHistoryProvider);
    final ideal = ref.watch(assessmentProvider)?.idealWeightKg;

    if (points.length < 2) {
      return SectionCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Text('📉', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(child: Text(context.tr('health.trendHint'))),
          ],
        ),
      );
    }

    final delta = points.last.$2 - points.first.$2;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(context.tr('health.weightTrend'),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Text(
                '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: delta <= 0 ? LifeColors.finance : LifeColors.goals,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _WeightLinePainter(
                points: points,
                ideal: ideal,
                lineColor: Theme.of(context).colorScheme.primary,
                gridColor: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat.MMMd().format(points.first.$1),
                  style: Theme.of(context).textTheme.labelSmall),
              if (ideal != null)
                Text(
                  '${context.tr('health.idealLine')}: '
                  '${ideal.toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              Text(DateFormat.MMMd().format(points.last.$1),
                  style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightLinePainter extends CustomPainter {
  final List<(DateTime, double)> points;
  final double? ideal;
  final Color lineColor;
  final Color gridColor;

  _WeightLinePainter({
    required this.points,
    required this.ideal,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var min = points.first.$2;
    var max = points.first.$2;
    for (final p in points) {
      if (p.$2 < min) min = p.$2;
      if (p.$2 > max) max = p.$2;
    }
    final guide = ideal;
    if (guide != null) {
      if (guide < min) min = guide;
      if (guide > max) max = guide;
    }
    final pad = ((max - min) * 0.15).clamp(0.5, 10.0);
    min -= pad;
    max += pad;

    double yOf(double kg) => size.height * (1 - (kg - min) / (max - min));
    double xOf(int i) =>
        points.length == 1 ? size.width / 2 : size.width * i / (points.length - 1);

    // Dashed ideal-weight guide.
    if (guide != null) {
      final dash = Paint()
        ..color = gridColor
        ..strokeWidth = 1.4;
      final y = yOf(guide);
      for (double x = 0; x < size.width; x += 10) {
        canvas.drawLine(Offset(x, y), Offset(x + 5, y), dash);
      }
    }

    // Trend line + dots.
    final line = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final o = Offset(xOf(i), yOf(points[i].$2));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(path, line);

    final dot = Paint()..color = lineColor;
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(Offset(xOf(i), yOf(points[i].$2)), 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightLinePainter old) =>
      old.points != points || old.ideal != ideal;
}

/// Steps for the last 7 days (archived days + today) against the step goal.
class StepsWeekCard extends ConsumerWidget {
  const StepsWeekCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MetricWeekCard(
        titleKey: 'health.stepsWeek',
        goal: ref.watch(healthGoalsProvider).steps.toDouble(),
        barColor: LifeColors.finance,
        value: (d) => d.steps.toDouble(),
      );
}

/// Water glasses for the last 7 days against the water goal.
class WaterWeekCard extends ConsumerWidget {
  const WaterWeekCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MetricWeekCard(
        titleKey: 'health.waterWeek',
        goal: ref.watch(healthGoalsProvider).water.toDouble(),
        barColor: const Color(0xFF3BA7FF),
        value: (d) => d.waterGlasses.toDouble(),
      );
}

/// Sleep hours for the last 7 days against the sleep goal.
class SleepWeekCard extends ConsumerWidget {
  const SleepWeekCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MetricWeekCard(
        titleKey: 'health.sleepWeek',
        goal: ref.watch(healthGoalsProvider).sleep,
        barColor: LifeColors.mind,
        value: (d) => d.sleepHours,
      );
}

/// A reusable 7-day bar chart for any health metric: archived days + today,
/// bars vs a dashed goal line, brighter when the goal was met.
class MetricWeekCard extends ConsumerWidget {
  final String titleKey;
  final double goal;
  final Color barColor;
  final double Function(HealthDay day) value;

  const MetricWeekCard({
    required this.titleKey,
    required this.goal,
    required this.barColor,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(healthHistoryProvider);
    final today = ref.watch(todayHealthProvider).valueOrNull;
    final days = <HealthDay>[
      ...history.length > 6 ? history.sublist(history.length - 6) : history,
      if (today != null) today,
    ];
    if (days.length < 2) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr(titleKey),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              width: double.infinity,
              child: CustomPaint(
                painter: _MetricBarsPainter(
                  values: [for (final d in days) value(d)],
                  goal: goal,
                  barColor: barColor,
                  goalColor: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final d in days)
                  Text(DateFormat.E().format(d.date),
                      style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBarsPainter extends CustomPainter {
  final List<double> values;
  final double goal;
  final Color barColor;
  final Color goalColor;

  _MetricBarsPainter({
    required this.values,
    required this.goal,
    required this.barColor,
    required this.goalColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var max = goal;
    for (final v in values) {
      if (v > max) max = v;
    }
    if (max <= 0) return;

    // Goal line (dashed).
    final goalY = size.height * (1 - goal / max);
    final dash = Paint()
      ..color = goalColor
      ..strokeWidth = 1.4;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, goalY), Offset(x + 5, goalY), dash);
    }

    final groupW = size.width / values.length;
    final barW = groupW * 0.5;
    for (var i = 0; i < values.length; i++) {
      final h = size.height * values[i] / max;
      final reached = values[i] >= goal;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            groupW * i + (groupW - barW) / 2,
            size.height - h,
            barW,
            h,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = barColor.withValues(alpha: reached ? 1.0 : 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MetricBarsPainter old) =>
      old.values != values || old.goal != goal;
}

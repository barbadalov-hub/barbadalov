import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/health/domain/entities/measurement.dart';
import 'package:lifeos/features/health/presentation/providers/measurement_providers.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// Track body measurements (cm) over time, with per-field trend and change.
class MeasurementsPage extends ConsumerWidget {
  const MeasurementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(measurementsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('meas.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.pulse,
        color: LifeColors.health,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(context.tr('meas.intro'),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            for (final field in MeasurementField.values)
              _FieldCard(field: field, series: measurementSeries(all, field)),
          ],
        ),
      ),
    );
  }
}

class _FieldCard extends ConsumerWidget {
  final MeasurementField field;
  final List<MeasurementEntry> series;
  const _FieldCard({required this.field, required this.series});

  double? _profileValue(UserProfile? p) => switch (field) {
        MeasurementField.waist => p?.waistCm,
        MeasurementField.chest => p?.chestCm,
        MeasurementField.hips => p?.hipsCm,
        MeasurementField.arm => p?.armCm,
        MeasurementField.neck => p?.neckCm,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = series.isNotEmpty ? series.last.cm : null;
    final delta = series.length >= 2 ? series.last.cm - series.first.cm : null;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(field.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(context.tr(field.labelKey),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              if (latest != null)
                Text('${_fmt(latest)} cm',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _logDialog(context, ref),
              ),
            ],
          ),
          if (delta != null) ...[
            const SizedBox(height: 2),
            Text(
              context.trp('meas.change', {
                'sign': delta >= 0 ? '+' : '',
                'n': _fmt(delta),
              }),
              style: TextStyle(
                fontSize: 12,
                color: delta <= 0 ? const Color(0xFF2E9E6B) : LifeColors.health,
              ),
            ),
          ],
          if (series.length >= 2) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: CustomPaint(painter: _Sparkline(series)),
            ),
          ] else if (latest == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(context.tr('meas.none'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      )),
            ),
        ],
      ),
    );
  }

  Future<void> _logDialog(BuildContext context, WidgetRef ref) async {
    final prefill = series.isNotEmpty
        ? series.last.cm
        : _profileValue(ref.read(profileProvider));
    final controller = TextEditingController(
        text: prefill == null ? '' : _fmt(prefill));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${field.emoji} ${ctx.tr(field.labelKey)}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            labelText: ctx.tr('meas.value'),
            suffixText: 'cm',
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
    if (result != null && result > 0) {
      ref.read(measurementsProvider.notifier).log(field, result);
    }
  }

  String _fmt(double v) => v == v.roundToDouble()
      ? '${v.round()}'
      : v.toStringAsFixed(1);
}

class _Sparkline extends CustomPainter {
  final List<MeasurementEntry> series;
  _Sparkline(this.series);

  @override
  void paint(Canvas canvas, Size size) {
    if (series.length < 2) return;
    var min = series.first.cm;
    var max = series.first.cm;
    for (final e in series) {
      if (e.cm < min) min = e.cm;
      if (e.cm > max) max = e.cm;
    }
    final range = (max - min).abs() < 0.001 ? 1.0 : max - min;
    final dx = size.width / (series.length - 1);
    final path = Path();
    for (var i = 0; i < series.length; i++) {
      final x = dx * i;
      final y = size.height - ((series[i].cm - min) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = LifeColors.health,
    );
  }

  @override
  bool shouldRepaint(covariant _Sparkline old) => old.series != series;
}

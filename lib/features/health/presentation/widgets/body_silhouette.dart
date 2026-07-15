import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/health/domain/entities/measurement.dart';
import 'package:lifeos/features/health/domain/measurement_targets.dart';
import 'package:lifeos/features/health/presentation/providers/measurement_providers.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// Chest / waist / hips in cm for a body shape, with fallbacks so a shape can
/// always be drawn: latest (or first) reading → profile tape value → the
/// athletic target reference.
class _Dims {
  final double chest;
  final double waist;
  final double hips;
  const _Dims(this.chest, this.waist, this.hips);

  double get max => [chest, waist, hips].reduce((a, b) => a > b ? a : b);
}

/// An approximate, parametric body silhouette (male/female) that morphs with
/// the user's measurements, shown as **before → after** so changes are visible.
///
/// This is a schematic 2D shape, not a 3D scan or a photo reconstruction —
/// those need native ML/3D engines the plugin-free web build can't ship.
class BodyShapeCard extends ConsumerWidget {
  const BodyShapeCard({super.key});

  double _fieldValue(
    List<MeasurementEntry> all,
    MeasurementField field,
    UserProfile p, {
    required bool latest,
  }) {
    final series = measurementSeries(all, field);
    if (series.isNotEmpty) return latest ? series.last.cm : series.first.cm;
    final tape = switch (field) {
      MeasurementField.chest => p.chestCm,
      MeasurementField.waist => p.waistCm,
      MeasurementField.hips => p.hipsCm,
      _ => null,
    };
    return tape ?? measurementTarget(field, p).idealCm;
  }

  _Dims _dims(List<MeasurementEntry> all, UserProfile p,
          {required bool latest}) =>
      _Dims(
        _fieldValue(all, MeasurementField.chest, p, latest: latest),
        _fieldValue(all, MeasurementField.waist, p, latest: latest),
        _fieldValue(all, MeasurementField.hips, p, latest: latest),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    if (profile == null) return const SizedBox.shrink();
    final all = ref.watch(measurementsProvider);

    final first = _dims(all, profile, latest: false);
    final last = _dims(all, profile, latest: true);
    final male = profile.sex == Sex.male;

    // Shared scale so the two figures are directly comparable.
    final maxCm = [first.max, last.max].reduce((a, b) => a > b ? a : b);
    final pxPerCm = maxCm <= 0 ? 1.0 : (86 * 0.9) / (maxCm / 2);

    final changed = first != last;
    final waistDelta = last.waist - first.waist;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🧍 ${context.tr('body.title')}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(context.tr('body.sub'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  )),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (changed) ...[
                _figure(context, male, first, pxPerCm,
                    Theme.of(context).colorScheme.outline, context.tr('body.before')),
                const SizedBox(width: 24),
                _figure(context, male, last, pxPerCm, LifeColors.health,
                    context.tr('body.after')),
              ] else
                _figure(context, male, last, pxPerCm, LifeColors.health,
                    context.tr('body.now')),
            ],
          ),
          if (changed) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                context.trp('body.waistChange', {
                  'sign': waistDelta > 0 ? '+' : '',
                  'n': waistDelta == waistDelta.roundToDouble()
                      ? '${waistDelta.round()}'
                      : waistDelta.toStringAsFixed(1),
                }),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: waistDelta <= 0
                      ? const Color(0xFF2E9E6B)
                      : LifeColors.health,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _figure(BuildContext context, bool male, _Dims d, double pxPerCm,
          Color color, String label) =>
      Column(
        children: [
          SizedBox(
            width: 100,
            height: 190,
            child: CustomPaint(
              painter: _BodyPainter(
                male: male,
                chestCm: d.chest,
                waistCm: d.waist,
                hipCm: d.hips,
                pxPerCm: pxPerCm,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      );
}

class _BodyPainter extends CustomPainter {
  final bool male;
  final double chestCm;
  final double waistCm;
  final double hipCm;
  final double pxPerCm;
  final Color color;

  _BodyPainter({
    required this.male,
    required this.chestCm,
    required this.waistCm,
    required this.hipCm,
    required this.pxPerCm,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    double half(double cm) => (cm / 2) * pxPerCm;

    final shoulderHalf = half(chestCm) * (male ? 1.08 : 1.0);
    final waistHalf = half(waistCm);
    final hipHalf = half(hipCm) * (male ? 1.0 : 1.06);

    final headR = h * 0.06;
    final headY = h * 0.09;
    final shoulderY = h * 0.22;
    final waistY = h * 0.47;
    final hipY = h * 0.57;
    final crotchY = h * 0.63;
    final bottomY = h * 0.96;

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.28);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    canvas.drawCircle(Offset(cx, headY), headR, fill);
    canvas.drawCircle(Offset(cx, headY), headR, stroke);

    final body = Path()
      ..moveTo(cx - shoulderHalf, shoulderY)
      ..lineTo(cx - waistHalf, waistY)
      ..lineTo(cx - hipHalf, hipY)
      ..lineTo(cx - hipHalf * 0.55, bottomY)
      ..lineTo(cx - hipHalf * 0.12, bottomY)
      ..lineTo(cx, crotchY)
      ..lineTo(cx + hipHalf * 0.12, bottomY)
      ..lineTo(cx + hipHalf * 0.55, bottomY)
      ..lineTo(cx + hipHalf, hipY)
      ..lineTo(cx + waistHalf, waistY)
      ..lineTo(cx + shoulderHalf, shoulderY)
      ..close();
    canvas.drawPath(body, fill);
    canvas.drawPath(body, stroke);

    final arm = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.5);
    canvas.drawLine(Offset(cx - shoulderHalf * 0.92, shoulderY + 2),
        Offset(cx - waistHalf - 5, waistY), arm);
    canvas.drawLine(Offset(cx + shoulderHalf * 0.92, shoulderY + 2),
        Offset(cx + waistHalf + 5, waistY), arm);
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) =>
      old.chestCm != chestCm ||
      old.waistCm != waistCm ||
      old.hipCm != hipCm ||
      old.pxPerCm != pxPerCm ||
      old.color != color ||
      old.male != male;
}

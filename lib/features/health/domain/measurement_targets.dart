import 'package:lifeos/features/health/domain/entities/measurement.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';

/// An approximate reference for a body measurement, derived from height and
/// sex. [idealCm] is an athletic proportion reference; [healthyMaxCm] is a
/// health ceiling (used for waist, per WHO risk thresholds).
///
/// These are rough, educational proportions — real "ideal" numbers vary with
/// frame and training. They exist to give the user a direction, not a verdict.
class MeasurementTarget {
  final double idealCm;
  final double? healthyMaxCm;
  const MeasurementTarget(this.idealCm, {this.healthyMaxCm});
}

/// Approximate athletic reference for [field] given the user's height and sex.
MeasurementTarget measurementTarget(MeasurementField field, UserProfile p) {
  final h = p.heightCm;
  final male = p.sex == Sex.male;
  return switch (field) {
    // Waist: athletic ≈ 0.45×height; WHO health ceiling 94 cm (m) / 80 cm (f).
    MeasurementField.waist =>
      MeasurementTarget(0.45 * h, healthyMaxCm: male ? 94 : 80),
    MeasurementField.chest => MeasurementTarget((male ? 0.52 : 0.50) * h),
    MeasurementField.hips => MeasurementTarget((male ? 0.51 : 0.55) * h),
    MeasurementField.arm => MeasurementTarget((male ? 0.19 : 0.16) * h),
    MeasurementField.neck => MeasurementTarget((male ? 0.21 : 0.19) * h),
  };
}

/// Whether [cm] is over the health ceiling for [field] (waist only today).
bool overHealthyMax(MeasurementField field, UserProfile p, double cm) {
  final max = measurementTarget(field, p).healthyMaxCm;
  return max != null && cm > max;
}

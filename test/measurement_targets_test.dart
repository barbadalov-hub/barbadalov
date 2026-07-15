import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/health/domain/entities/measurement.dart';
import 'package:lifeos/features/health/domain/measurement_targets.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';

UserProfile _p({Sex sex = Sex.male, double height = 180}) => UserProfile(
      name: 'A',
      sex: sex,
      age: 30,
      heightCm: height,
      weightKg: 80,
    );

void main() {
  group('measurementTarget', () {
    test('waist target scales with height and carries a health ceiling', () {
      final t = measurementTarget(MeasurementField.waist, _p(height: 180));
      expect(t.idealCm, closeTo(81, 0.001)); // 0.45 * 180
      expect(t.healthyMaxCm, 94); // male WHO threshold
    });

    test('female waist ceiling is 80 cm', () {
      final t = measurementTarget(MeasurementField.waist, _p(sex: Sex.female));
      expect(t.healthyMaxCm, 80);
    });

    test('non-waist fields have no health ceiling', () {
      for (final f in [
        MeasurementField.chest,
        MeasurementField.hips,
        MeasurementField.arm,
        MeasurementField.neck,
      ]) {
        expect(measurementTarget(f, _p()).healthyMaxCm, isNull);
      }
    });

    test('overHealthyMax flags a large male waist', () {
      final p = _p();
      expect(overHealthyMax(MeasurementField.waist, p, 100), isTrue);
      expect(overHealthyMax(MeasurementField.waist, p, 88), isFalse);
      // Fields without a ceiling never flag.
      expect(overHealthyMax(MeasurementField.arm, p, 999), isFalse);
    });
  });
}

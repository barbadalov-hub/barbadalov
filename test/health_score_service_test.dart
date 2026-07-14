import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/health_score_service.dart';
import 'package:lifeos/features/health/domain/entities/health_day.dart';

void main() {
  const service = HealthScoreService();
  final date = DateTime(2026, 1, 1);

  group('HealthScoreService', () {
    test('all three goals met scores 100', () {
      final s = service.scoreFor(HealthDay(
        date: date,
        waterMl: 8 * 250,
        steps: 10000,
        sleepHours: 8,
      ));
      expect(s, 100);
    });

    test('halfway to every goal scores 50', () {
      final s = service.scoreFor(HealthDay(
        date: date,
        waterMl: 4 * 250,
        steps: 5000,
        sleepHours: 4,
      ));
      expect(s, 50);
    });

    test('exceeding goals is capped at 100% per metric', () {
      final s = service.scoreFor(HealthDay(
        date: date,
        waterMl: 20 * 250,
        steps: 30000,
        sleepHours: 12,
      ));
      expect(s, 100);
    });

    test('an empty day scores 0', () {
      expect(service.scoreFor(HealthDay(date: date)), 0);
    });

    test('averages the three metrics independently', () {
      // water full (100%), no steps (0%), half sleep (50%) -> (1+0+0.5)/3 -> 50.
      final s = service.scoreFor(HealthDay(
        date: date,
        waterMl: 8 * 250,
        steps: 0,
        sleepHours: 4,
      ));
      expect(s, 50);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/health_score_service.dart';
import 'package:lifeos/features/health/domain/entities/health_day.dart';

HealthDay _day({int steps = 0, int waterMl = 0, double sleep = 0}) =>
    HealthDay(
      date: DateTime(2026, 8, 18),
      steps: steps,
      waterMl: waterMl,
      sleepHours: sleep,
    );

void main() {
  const service = HealthScoreService();

  test('training raises the score', () {
    final day = _day(steps: 5000, waterMl: 1000, sleep: 7);
    final without = service.scoreFor(day);
    final with30 = service.scoreFor(day, activeMinutes: 30);
    expect(with30, greaterThan(without));
  });

  /// The decision this whole shape exists to protect.
  test('training can never lower a score', () {
    // Making it a fourth equal part would have dropped everyone who does not
    // log workouts: same day, same habits, worse number, purely because the
    // app grew a feature.
    for (final day in [
      _day(),
      _day(steps: 3000),
      _day(steps: 12000, waterMl: 2500, sleep: 8),
      _day(waterMl: 500, sleep: 4),
    ]) {
      expect(service.scoreFor(day, activeMinutes: 0), service.scoreFor(day),
          reason: 'no training must read exactly as before the feature');
      expect(service.scoreFor(day, activeMinutes: 45),
          greaterThanOrEqualTo(service.scoreFor(day)));
    }
  });

  test('the bonus is capped, so a marathon is not worth a whole day', () {
    final day = _day(steps: 5000, waterMl: 1000, sleep: 7);
    final at30 = service.scoreFor(day, activeMinutes: 30);
    final at300 = service.scoreFor(day, activeMinutes: 300);
    expect(at300, at30,
        reason: 'past the daily target more minutes add nothing');
  });

  test('a perfect day stays at 100 rather than overflowing', () {
    final perfect = _day(steps: 20000, waterMl: 4000, sleep: 9);
    expect(service.scoreFor(perfect, activeMinutes: 120), 100);
  });

  test('training alone does not fake a healthy day', () {
    // Someone who trained but drank nothing and barely slept should not come
    // out looking fine.
    expect(service.scoreFor(_day(), activeMinutes: 60),
        lessThanOrEqualTo(HealthScoreService.trainingBonus));
  });
}

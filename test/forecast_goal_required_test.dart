import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/goals/application/forecast_goal.dart';
import 'package:lifeos/features/goals/domain/entities/goal.dart';
import 'package:lifeos/shared/models/money.dart';

Goal _goal({required int targetMinor, int savedMinor = 0, DateTime? targetDate}) =>
    Goal(
      id: 'g',
      title: 'Fund',
      emoji: '🎯',
      target: Money(targetMinor),
      saved: Money(savedMinor),
      targetDate: targetDate,
    );

void main() {
  const forecast = ForecastGoal();
  final now = DateTime(2026, 1, 15);

  group('ForecastGoal.requiredMonthly', () {
    test('spreads the remaining amount over the months until the target', () {
      final f = forecast(
        _goal(targetMinor: 120000, targetDate: DateTime(2026, 7, 1)),
        monthlyNet: const Money(10000),
        now: now,
      );
      // 6 months until July -> 120000 / 6 = 20000.
      expect(f.requiredMonthly, const Money(20000));
    });

    test('rounds the required contribution up', () {
      final f = forecast(
        _goal(targetMinor: 100000, targetDate: DateTime(2026, 7, 20)),
        monthlyNet: const Money(10000),
        now: now,
      );
      // 6 months -> ceil(16666.67) = 16667.
      expect(f.requiredMonthly, const Money(16667));
    });

    test('is still reported when nothing is being saved yet', () {
      final f = forecast(
        _goal(targetMinor: 60000, targetDate: DateTime(2026, 4, 1)),
        monthlyNet: const Money.zero(),
        now: now,
      );
      expect(f.monthsRemaining, isNull); // can't project a date
      expect(f.requiredMonthly, const Money(20000)); // but here's the plan
    });

    test('no target date means no required figure', () {
      final f = forecast(
        _goal(targetMinor: 100000),
        monthlyNet: const Money(10000),
        now: now,
      );
      expect(f.requiredMonthly, isNull);
    });

    test('a target in the current month or the past yields no figure', () {
      final thisMonth = forecast(
        _goal(targetMinor: 100000, targetDate: DateTime(2026, 1, 28)),
        monthlyNet: const Money(10000),
        now: now,
      );
      final past = forecast(
        _goal(targetMinor: 100000, targetDate: DateTime(2025, 12, 1)),
        monthlyNet: const Money(10000),
        now: now,
      );
      expect(thisMonth.requiredMonthly, isNull);
      expect(past.requiredMonthly, isNull);
    });

    test('preserves the goal currency', () {
      final f = forecast(
        Goal(
          id: 'g',
          title: 'Fund',
          emoji: '🎯',
          target: const Money(120000, currency: 'UAH'),
          saved: const Money.zero(currency: 'UAH'),
          targetDate: DateTime(2026, 7, 1),
        ),
        monthlyNet: const Money(10000, currency: 'UAH'),
        now: now,
      );
      expect(f.requiredMonthly?.currency, 'UAH');
    });
  });
}

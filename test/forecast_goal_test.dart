import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/goals/application/forecast_goal.dart';
import 'package:lifeos/features/goals/domain/entities/goal.dart';
import 'package:lifeos/shared/models/money.dart';

Goal _goal({
  required int targetMinor,
  required int savedMinor,
  DateTime? targetDate,
}) =>
    Goal(
      id: 'g1',
      title: 'Move city',
      emoji: '🏙️',
      target: Money(targetMinor),
      saved: Money(savedMinor),
      targetDate: targetDate,
    );

void main() {
  const forecast = ForecastGoal();
  final now = DateTime(2026, 1, 15);

  group('ForecastGoal', () {
    test('an already-funded goal reports complete', () {
      final f = forecast(
        _goal(targetMinor: 100000, savedMinor: 100000),
        monthlyNet: const Money(20000),
        now: now,
      );
      expect(f.complete, isTrue);
      expect(f.monthsRemaining, isNull);
    });

    test('no monthly savings cannot be projected and is off track', () {
      final f = forecast(
        _goal(targetMinor: 100000, savedMinor: 0),
        monthlyNet: const Money.zero(),
        now: now,
      );
      expect(f.monthsRemaining, isNull);
      expect(f.projectedDate, isNull);
      expect(f.onTrackForTargetDate, isFalse);
    });

    test('projects months and date from the savings rate', () {
      // remaining 100000, saving 25000/mo -> 4 months -> 2026-05-15.
      final f = forecast(
        _goal(targetMinor: 100000, savedMinor: 0),
        monthlyNet: const Money(25000),
        now: now,
      );
      expect(f.monthsRemaining, 4);
      expect(f.projectedDate, DateTime(2026, 5, 15));
      expect(f.onTrackForTargetDate, isTrue); // no target date
    });

    test('rounds partial months up (ceil)', () {
      // remaining 100000, saving 30000/mo -> 3.33 -> 4 months.
      final f = forecast(
        _goal(targetMinor: 100000, savedMinor: 0),
        monthlyNet: const Money(30000),
        now: now,
      );
      expect(f.monthsRemaining, 4);
    });

    test('flags a projection that lands after the target date', () {
      // 4 months out -> 2026-05-15, target 2026-03-01 -> late.
      final f = forecast(
        _goal(
          targetMinor: 100000,
          savedMinor: 0,
          targetDate: DateTime(2026, 3, 1),
        ),
        monthlyNet: const Money(25000),
        now: now,
      );
      expect(f.onTrackForTargetDate, isFalse);
    });

    test('a projection at or before the target date is on track', () {
      final f = forecast(
        _goal(
          targetMinor: 100000,
          savedMinor: 0,
          targetDate: DateTime(2026, 8, 1),
        ),
        monthlyNet: const Money(25000),
        now: now,
      );
      expect(f.onTrackForTargetDate, isTrue);
    });
  });
}

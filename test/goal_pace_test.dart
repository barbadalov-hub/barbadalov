import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/goals/domain/goal_pace.dart';

GoalContribution _c(DateTime at, int minor) =>
    GoalContribution(goalId: 'g', minorUnits: minor, at: at);

void main() {
  final now = DateTime(2026, 7, 1);

  test('a steady saver gets a date from their own behaviour', () {
    // 10 000 a month for three months, 60 000 still to go → six more months.
    final estimate = GoalPace.estimate(
      contributions: [
        _c(DateTime(2026, 4, 1), 1000000),
        _c(DateTime(2026, 5, 1), 1000000),
        _c(DateTime(2026, 6, 1), 1000000),
      ],
      remainingMinor: 6000000,
      now: now,
    )!;

    expect(estimate.perMonthMinor, closeTo(1000000, 60000));
    expect(estimate.monthsRemaining, inInclusiveRange(6, 7));
    expect(estimate.basedOn, 3);
  });

  group('when it refuses to guess', () {
    test('one top-up is not a pace', () {
      // Two points can be drawn through any line; one cannot even do that.
      expect(
        GoalPace.estimate(
          contributions: [_c(DateTime(2026, 6, 1), 500000)],
          remainingMinor: 1000000,
          now: now,
        ),
        isNull,
      );
    });

    test('an empty history has nothing to say', () {
      expect(
        GoalPace.estimate(
            contributions: const [], remainingMinor: 100000, now: now),
        isNull,
      );
    });

    test('a finished goal needs no forecast', () {
      expect(
        GoalPace.estimate(
          contributions: [
            _c(DateTime(2026, 5, 1), 100000),
            _c(DateTime(2026, 6, 1), 100000),
          ],
          remainingMinor: 0,
          now: now,
        ),
        isNull,
      );
    });
  });

  test('saving that stopped months ago is not still counted', () {
    // Everything is outside the window; the app must not report the pace of
    // someone who has long since gone quiet.
    expect(
      GoalPace.estimate(
        contributions: [
          _c(DateTime(2025, 1, 1), 1000000),
          _c(DateTime(2025, 2, 1), 1000000),
        ],
        remainingMinor: 5000000,
        now: now,
      ),
      isNull,
    );
  });

  test('going quiet slows the estimate rather than freezing it', () {
    // Two top-ups five months ago, nothing since. Measuring only the active
    // stretch would still claim a healthy monthly rate; measuring to *now*
    // reports the truth, which is that saving has nearly stalled.
    final estimate = GoalPace.estimate(
      contributions: [
        _c(DateTime(2026, 2, 1), 1000000),
        _c(DateTime(2026, 2, 20), 1000000),
      ],
      remainingMinor: 6000000,
      now: now,
    )!;

    expect(estimate.perMonthMinor, lessThan(600000),
        reason: 'five quiet months are part of the pace');
  });

  test('a flurry in one afternoon does not project to a fortune', () {
    final estimate = GoalPace.estimate(
      contributions: [
        _c(DateTime(2026, 6, 30, 10), 500000),
        _c(DateTime(2026, 6, 30, 11), 500000),
      ],
      remainingMinor: 10000000,
      now: DateTime(2026, 6, 30, 12),
    )!;

    // Held to a week of history, not one hour.
    expect(estimate.perMonthMinor, lessThanOrEqualTo(4300000));
  });

  test('the arrival date lands the right number of months out', () {
    final estimate = GoalPace.estimate(
      contributions: [
        _c(DateTime(2026, 5, 1), 1000000),
        _c(DateTime(2026, 6, 1), 1000000),
      ],
      remainingMinor: 3000000,
      now: DateTime(2026, 7, 15),
    )!;

    expect(
      estimate.arrivesOn.month,
      ((7 + estimate.monthsRemaining - 1) % 12) + 1,
    );
  });
}

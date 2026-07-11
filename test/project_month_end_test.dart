import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/money/application/project_month_end.dart';
import 'package:lifeos/shared/models/money.dart';

void main() {
  const project = ProjectMonthEnd();

  Money uah(int major) => Money.fromMajor(major, currency: 'UAH');

  group('ProjectMonthEnd', () {
    test('extrapolates spend linearly over the elapsed month', () {
      // Spent 300 over the first 10 days of a 30-day month → pace 30/day →
      // 900 projected. Spendable = 2000 − 400 = 1600 → 700 left.
      final p = project(
        income: uah(2000),
        expensesSoFar: uah(300),
        reserve: uah(400),
        dayOfMonth: 10,
        daysInMonth: 30,
      );
      expect(p.projectedSpend, uah(900));
      expect(p.dailyPace, uah(30));
      expect(p.projectedLeftover, uah(700));
      expect(p.onTrack, isTrue);
    });

    test('flags an overspending pace with a negative leftover', () {
      // 900 in 10 days → 2700 projected against 1600 spendable → −1100.
      final p = project(
        income: uah(2000),
        expensesSoFar: uah(900),
        reserve: uah(400),
        dayOfMonth: 10,
        daysInMonth: 30,
      );
      expect(p.projectedSpend, uah(2700));
      expect(p.projectedLeftover, uah(-1100));
      expect(p.onTrack, isFalse);
    });

    test('nothing spent yet leaves the whole spendable budget', () {
      final p = project(
        income: uah(1000),
        expensesSoFar: const Money.zero(currency: 'UAH'),
        reserve: uah(150),
        dayOfMonth: 1,
        daysInMonth: 31,
      );
      expect(p.projectedSpend, const Money.zero(currency: 'UAH'));
      expect(p.projectedLeftover, uah(850));
      expect(p.dailyPace, const Money.zero(currency: 'UAH'));
      expect(p.onTrack, isTrue);
    });

    test('on the last day the projection equals actual spend', () {
      final p = project(
        income: uah(1000),
        expensesSoFar: uah(500),
        reserve: uah(100),
        dayOfMonth: 31,
        daysInMonth: 31,
      );
      expect(p.projectedSpend, uah(500));
      expect(p.projectedLeftover, uah(400));
    });

    test('clamps a nonsensical day into the month and never divides by zero',
        () {
      final p = project(
        income: uah(1000),
        expensesSoFar: uah(200),
        reserve: uah(100),
        dayOfMonth: 0, // clamped to day 1
        daysInMonth: 0, // guarded to 1
      );
      // day→1, days→1: projected == spent so far.
      expect(p.projectedSpend, uah(200));
      expect(p.projectedLeftover, uah(700));
    });

    test('preserves the currency of the inputs', () {
      final p = project(
        income: uah(1000),
        expensesSoFar: uah(100),
        reserve: uah(100),
        dayOfMonth: 15,
        daysInMonth: 30,
      );
      expect(p.projectedSpend.currency, 'UAH');
      expect(p.projectedLeftover.currency, 'UAH');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/money/domain/afford_check.dart';

void main() {
  group('the verdict', () {
    test('a small purchase against a healthy month is easy', () {
      final a = AffordCheck.ask(
        amountMinor: 50000, // 500
        freeLeftMinor: 1200000, // 12 000
        daysLeftInMonth: 12,
      )!;
      expect(a.verdict, AffordVerdict.easy);
      expect(a.daysCost, 1);
      expect(a.params['left'], 1150000);
    });

    test('half of what is left is where it stops being a purchase', () {
      final a = AffordCheck.ask(
        amountMinor: 600000,
        freeLeftMinor: 1200000,
        daysLeftInMonth: 12,
      )!;
      expect(a.verdict, AffordVerdict.tight);
      expect(a.daysCost, 6);
    });

    test('more than there is gets a plain no, with the shortfall', () {
      final a = AffordCheck.ask(
        amountMinor: 1500000,
        freeLeftMinor: 1200000,
        daysLeftInMonth: 10,
      )!;
      expect(a.verdict, AffordVerdict.no);
      expect(a.reasonKey, 'afford.over');
      expect(a.params['over'], 300000);
    });

    test('already overspent is its own answer, not a division by zero', () {
      final a = AffordCheck.ask(
        amountMinor: 1000,
        freeLeftMinor: -5000,
        daysLeftInMonth: 8,
      )!;
      expect(a.verdict, AffordVerdict.no);
      expect(a.reasonKey, 'afford.nothingLeft');
    });
  });

  group('the days it costs', () {
    test('rounds up, because most of a day still costs you the day', () {
      // 1000 per day; 600 is 0.6 of a day and must not flatter itself to 0.
      final a = AffordCheck.ask(
        amountMinor: 600,
        freeLeftMinor: 30000,
        daysLeftInMonth: 30,
      )!;
      expect(a.daysCost, 1);
    });

    test('the last day of the month does not divide by zero', () {
      final a = AffordCheck.ask(
        amountMinor: 5000,
        freeLeftMinor: 20000,
        daysLeftInMonth: 0,
      )!;
      expect(a.daysCost, greaterThan(0));
      expect(a.daysCost.isFinite, isTrue);
    });
  });

  group('nothing typed is not a question', () {
    test('zero and negative amounts get no verdict at all', () {
      expect(
        AffordCheck.ask(
            amountMinor: 0, freeLeftMinor: 100000, daysLeftInMonth: 5),
        isNull,
      );
      expect(
        AffordCheck.ask(
            amountMinor: -100, freeLeftMinor: 100000, daysLeftInMonth: 5),
        isNull,
      );
    });
  });

  group('days left in the month', () {
    test('counts today', () {
      expect(AffordCheck.daysLeftInMonth(DateTime(2026, 1, 31)), 1);
      expect(AffordCheck.daysLeftInMonth(DateTime(2026, 1, 1)), 31);
    });

    test('handles February in a leap year and a common one', () {
      expect(AffordCheck.daysLeftInMonth(DateTime(2024, 2, 1)), 29);
      expect(AffordCheck.daysLeftInMonth(DateTime(2026, 2, 1)), 28);
    });

    test('handles December, where the next month is another year', () {
      expect(AffordCheck.daysLeftInMonth(DateTime(2026, 12, 25)), 7);
    });
  });
}

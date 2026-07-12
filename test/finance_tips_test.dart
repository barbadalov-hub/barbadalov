import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/money/application/finance_tips.dart';

void main() {
  group('FinanceTips.ofDay', () {
    test('is stable within a day', () {
      final a = FinanceTips.ofDay(DateTime(2026, 3, 4, 9));
      final b = FinanceTips.ofDay(DateTime(2026, 3, 4, 21));
      expect(a, b);
    });

    test('always returns a key from the catalog', () {
      for (var i = 0; i < 40; i++) {
        final tip = FinanceTips.ofDay(DateTime(2026, 1, 1).add(Duration(days: i)));
        expect(FinanceTips.keys, contains(tip));
      }
    });

    test('rotates through the whole list and wraps around', () {
      final start = DateTime(2026, 1, 1); // day-of-year 0
      final n = FinanceTips.keys.length;
      // Day 0 and day n land on the same tip (wrap); the n days between cover
      // every distinct key exactly once.
      expect(FinanceTips.ofDay(start), FinanceTips.keys.first);
      expect(
        FinanceTips.ofDay(start.add(Duration(days: n))),
        FinanceTips.ofDay(start),
      );
      final seen = <String>{
        for (var i = 0; i < n; i++)
          FinanceTips.ofDay(start.add(Duration(days: i))),
      };
      expect(seen.length, n);
    });

    test('consecutive days advance to the next tip', () {
      final d0 = DateTime(2026, 5, 10);
      final i0 = FinanceTips.keys.indexOf(FinanceTips.ofDay(d0));
      final i1 = FinanceTips.keys.indexOf(FinanceTips.ofDay(d0.add(const Duration(days: 1))));
      expect(i1, (i0 + 1) % FinanceTips.keys.length);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/shared/models/money.dart';

void main() {
  group('Money', () {
    test('fromMajor stores exact minor units', () {
      expect(Money.fromMajor(12.34).minorUnits, 1234);
      expect(Money.fromMajor(0).isZero, isTrue);
    });

    test('arithmetic is exact', () {
      final sum = Money.fromMajor(0.10) + Money.fromMajor(0.20);
      expect(sum.minorUnits, 30); // no floating point drift
    });

    test('clampToZero floors negatives', () {
      final debt = Money.fromMajor(5) - Money.fromMajor(8);
      expect(debt.isNegative, isTrue);
      expect(debt.clampToZero(), const Money.zero());
    });

    test('comparisons work on minor units', () {
      expect(Money.fromMajor(10) > Money.fromMajor(5), isTrue);
      expect(Money.fromMajor(5) <= Money.fromMajor(5), isTrue);
    });
  });
}

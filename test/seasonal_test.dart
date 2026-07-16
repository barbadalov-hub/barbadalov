import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/food/domain/seasonal.dart';

void main() {
  group('seasonal', () {
    test('seasonal produce is in season only in its months', () {
      expect(isInSeason('watermelon', 8), isTrue); // August
      expect(isInSeason('watermelon', 1), isFalse); // January
      expect(isInSeason('pumpkin', 10), isTrue);
      expect(isInSeason('pumpkin', 6), isFalse);
    });

    test('year-round staples are always in season', () {
      for (var m = 1; m <= 12; m++) {
        expect(isInSeason('eggs', m), isTrue);
        expect(isInSeason('chicken', m), isTrue);
      }
    });

    test('seasonalScore rewards in-season and penalises out-of-season', () {
      // A summer dish scores positive in summer, negative in winter.
      final summerDish = ['watermelon', 'feta']; // feta is year-round
      expect(seasonalScore(summerDish, 8), 1);
      expect(seasonalScore(summerDish, 1), -1);
      // Only staples → neutral.
      expect(seasonalScore(['eggs', 'milk', 'chicken'], 8), 0);
    });
  });
}

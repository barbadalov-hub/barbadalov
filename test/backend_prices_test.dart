import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/food/data/backend_price_source.dart';
import 'package:lifeos/features/food/data/ua_store_price_catalog.dart';
import 'package:lifeos/features/food/data/zakaz_price_source.dart';
import 'package:lifeos/shared/models/money.dart';

void main() {
  group('BackendPriceClient.parsePrices', () {
    test('keeps positive atb/silpo kopecks and drops junk', () {
      final out = BackendPriceClient.parsePrices({
        'prices': {
          'eggs': {'atb': 5490, 'silpo': 5990, 'novus': 6100}, // novus ignored
          'milk': {'atb': 0, 'silpo': 4290}, // zero dropped
          'bread': {'atb': 2550.0}, // num coerced to int
          'junk': 'nope',
        },
      });

      expect(out['eggs'], {'atb': 5490, 'silpo': 5990});
      expect(out['milk'], {'silpo': 4290});
      expect(out['bread'], {'atb': 2550});
      expect(out.containsKey('junk'), isFalse);
    });

    test('malformed payload yields empty', () {
      expect(BackendPriceClient.parsePrices({'nope': 1}), isEmpty);
      expect(BackendPriceClient.parsePrices({'prices': 'x'}), isEmpty);
    });
  });

  group('CompositePriceSource overlay', () {
    test('live АТБ price overrides the offline one; Сільпо stays offline', () {
      const base = UaStorePriceCatalog();
      final offline = {
        for (final q in base.quotesFor('eggs')) q.store.id: q.price.minorUnits,
      };
      expect(offline.containsKey('atb'), isTrue);

      // Only a live АТБ price for eggs; Сільpo/Novus have none.
      const composite = CompositePriceSource(base, {
        'eggs': {'atb': 4990},
      });

      final quotes = {
        for (final q in composite.quotesFor('eggs')) q.store.id: q.price,
      };
      // АТБ now the live value…
      expect(quotes['atb'], const Money(4990, currency: 'UAH'));
      // …Сільпо unchanged from the catalog (not dropped).
      expect(quotes['silpo']!.minorUnits, offline['silpo']);
    });

    test('with no live data the composite equals the offline catalog', () {
      const base = UaStorePriceCatalog();
      const composite = CompositePriceSource(base, {});
      expect(composite.quotesFor('eggs').length, base.quotesFor('eggs').length);
    });
  });
}

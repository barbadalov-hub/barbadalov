import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/food/data/ua_store_price_catalog.dart';
import 'package:lifeos/features/food/data/zakaz_price_source.dart';
import 'package:lifeos/shared/models/money.dart';

void main() {
  group('ZakazUaClient.parseFirstPriceKopecks', () {
    test('reads the first valid price from a real-shaped payload', () {
      // Shape captured from the live API (kopecks in `price`).
      final body = {
        'count': 329,
        'results': [
          {'title': 'Молоко Barista 2,5% 950г', 'price': 6899, 'unit': 'pcs'},
          {'title': 'Інше молоко', 'price': 7405},
        ],
      };
      expect(ZakazUaClient.parseFirstPriceKopecks(body), 6899);
    });

    test('skips zero/invalid prices and survives junk', () {
      expect(
        ZakazUaClient.parseFirstPriceKopecks({
          'results': [
            {'price': 0},
            {'price': 'N/A'},
            {'price': 5100},
          ],
        }),
        5100,
      );
      expect(ZakazUaClient.parseFirstPriceKopecks({'results': []}), isNull);
      expect(ZakazUaClient.parseFirstPriceKopecks({}), isNull);
    });

    test('every catalog product has a Ukrainian search query', () {
      const catalog = UaStorePriceCatalog();
      for (final id in ZakazUaClient.queries.keys) {
        expect(catalog.quotesFor(id), isNotEmpty, reason: id);
      }
    });
  });

  group('CompositePriceSource', () {
    test('overlays live chain prices and keeps АТБ/Сільпо offline', () {
      const source = CompositePriceSource(
        UaStorePriceCatalog(),
        {
          'milk': {'novus': 6899, 'metro': 6550},
        },
      );
      final quotes = source.quotesFor('milk');
      final byStore = {for (final q in quotes) q.store.id: q.price};

      expect(byStore['novus'], const Money(6899, currency: 'UAH')); // live
      expect(byStore['metro'], const Money(6550, currency: 'UAH')); // live
      expect(byStore['atb'], Money.fromMajor(44, currency: 'UAH')); // catalog
      expect(byStore.containsKey('silpo'), isTrue);
    });

    test('without live data behaves exactly like the catalog', () {
      const source = CompositePriceSource(UaStorePriceCatalog(), {});
      expect(source.quotesFor('eggs').length, 3);
      expect(source.stores.length, 3);
    });
  });
}

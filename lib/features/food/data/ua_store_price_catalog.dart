import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/domain/repositories/store_price_source.dart';
import 'package:lifeos/shared/models/money.dart';

/// Curated Ukrainian grocery prices (UAH per standard pack) for the launch
/// stores — АТБ, Сільпо, Novus. Values are realistic mid-2026 shelf prices and
/// clearly marked as approximate in the UI. Swap this class for a live
/// scraper/backend adapter behind [StorePriceSource] without touching the UI.
class UaStorePriceCatalog implements StorePriceSource {
  const UaStorePriceCatalog();

  static const atb = Store('atb', 'АТБ');
  static const silpo = Store('silpo', 'Сільпо');
  static const novus = Store('novus', 'Novus');

  @override
  List<Store> get stores => const [atb, silpo, novus];

  /// productId → (packAmount, packUnit, [АТБ, Сільпо, Novus] price in UAH).
  static const Map<String, (int, PortionUnit, List<double>)> _catalog = {
    'eggs': (10, PortionUnit.pcs, [62, 68, 72]),
    'milk': (1000, PortionUnit.ml, [44, 47, 50]),
    'cottage_cheese': (400, PortionUnit.g, [88, 95, 102]),
    'oats': (500, PortionUnit.g, [38, 44, 48]),
    'banana': (1000, PortionUnit.g, [65, 69, 74]),
    'walnuts': (100, PortionUnit.g, [55, 60, 66]),
    'flour': (1000, PortionUnit.g, [32, 35, 39]),
    'honey': (250, PortionUnit.g, [95, 105, 115]),
    'cheese': (200, PortionUnit.g, [92, 99, 108]),
    'tomatoes': (1000, PortionUnit.g, [75, 82, 88]),
    'cucumbers': (1000, PortionUnit.g, [68, 74, 80]),
    'chicken': (1000, PortionUnit.g, [175, 189, 199]),
    'beef': (1000, PortionUnit.g, [320, 345, 365]),
    'fish': (1000, PortionUnit.g, [155, 168, 180]),
    'buckwheat': (1000, PortionUnit.g, [55, 60, 66]),
    'rice': (1000, PortionUnit.g, [62, 68, 74]),
    'beets': (1000, PortionUnit.g, [18, 22, 25]),
    'potatoes': (1000, PortionUnit.g, [22, 26, 30]),
    'carrots': (1000, PortionUnit.g, [20, 24, 28]),
    'onion': (1000, PortionUnit.g, [19, 23, 26]),
    'bread': (1, PortionUnit.pcs, [32, 36, 40]),
    'yogurt': (300, PortionUnit.g, [42, 46, 51]),
    'apple': (1000, PortionUnit.g, [38, 42, 46]),
  };

  @override
  List<StoreQuote> quotesFor(String productId) {
    final entry = _catalog[productId];
    if (entry == null) return const [];
    final (amount, unit, prices) = entry;
    final storeList = stores;
    return [
      for (var i = 0; i < storeList.length; i++)
        StoreQuote(
          store: storeList[i],
          price: Money.fromMajor(prices[i], currency: 'UAH'),
          packAmount: amount,
          packUnit: unit,
        ),
    ];
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/domain/repositories/store_price_source.dart';
import 'package:lifeos/shared/models/money.dart';

/// Live Ukrainian grocery prices from the **public zakaz.ua stores API** — no
/// account or API key needed (verified live: `GET stores-api.zakaz.ua/stores/`
/// and `/stores/{id}/products/search/?q=...` return JSON, prices in kopecks).
///
/// zakaz.ua carries Novus / METRO / Auchan. АТБ and Сільпо have no public API,
/// so they stay on the curated offline catalog and these three chains go live.
/// On web the browser blocks cross-origin calls (CORS) — refresh fails
/// gracefully and offline prices remain; on native (Windows/mobile) it works.
class ZakazUaClient {
  final http.Client _http;
  ZakazUaClient([http.Client? client]) : _http = client ?? http.Client();

  static const chains = <(String id, String name, String storeId)>[
    ('novus', 'Novus', '482010105'),
    ('metro', 'METRO', '48215610'),
    ('auchan', 'Auchan', '48246401'),
  ];

  /// Ukrainian search query per catalog product id.
  static const queries = <String, String>{
    'eggs': 'яйця курячі',
    'milk': 'молоко 2,5',
    'cottage_cheese': 'сир кисломолочний',
    'oats': 'пластівці вівсяні',
    'banana': 'банан',
    'walnuts': 'горіх волоський',
    'flour': 'борошно пшеничне',
    'honey': 'мед',
    'cheese': 'сир твердий',
    'tomatoes': 'помідори',
    'cucumbers': 'огірки',
    'chicken': 'філе куряче',
    'beef': 'яловичина',
    'fish': 'хек',
    'buckwheat': 'крупа гречана',
    'rice': 'рис',
    'beets': 'буряк',
    'potatoes': 'картопля',
    'carrots': 'морква',
    'onion': 'цибуля ріпчаста',
    'bread': 'хліб',
    'yogurt': 'йогурт',
    'apple': 'яблука',
  };

  /// The first available product's price in **kopecks**, or null.
  /// Pure parsing lives in [parseFirstPriceKopecks] so it is unit-testable.
  Future<int?> priceKopecks(String storeId, String query) async {
    try {
      final uri = Uri.parse(
        'https://stores-api.zakaz.ua/stores/$storeId/products/search/'
        '?q=${Uri.encodeQueryComponent(query)}',
      );
      final res = await _http.get(
        uri,
        headers: {'Accept-Language': 'uk'},
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      return parseFirstPriceKopecks(
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
      );
    } catch (_) {
      return null; // offline / CORS / API change → caller keeps fallback
    }
  }

  static int? parseFirstPriceKopecks(Map<String, dynamic> body) {
    final results = body['results'];
    if (results is! List || results.isEmpty) return null;
    for (final raw in results) {
      if (raw is! Map<String, dynamic>) continue;
      final price = raw['price'];
      if (price is int && price > 0) return price;
    }
    return null;
  }

  /// Fetch live prices for [productIds] across all chains in parallel.
  /// Returns productId → chainId → kopecks (only successful lookups).
  Future<Map<String, Map<String, int>>> fetchAll(
    Set<String> productIds,
  ) async {
    final out = <String, Map<String, int>>{};
    final futures = <Future<void>>[];
    for (final id in productIds) {
      final query = queries[id];
      if (query == null) continue;
      for (final (chainId, _, storeId) in chains) {
        futures.add(priceKopecks(storeId, query).then((kop) {
          if (kop != null) (out[id] ??= {})[chainId] = kop;
        }));
      }
    }
    await Future.wait(futures).timeout(
      const Duration(seconds: 20),
      onTimeout: () => const [],
    );
    return out;
  }
}

/// Offline catalog + live overlay. For each live-managed chain (Novus/METRO/
/// Auchan from zakaz.ua, plus АТБ/Сільпо from the self-hosted scraper) a live
/// price replaces the offline one; when a chain has no live price for a product
/// its curated offline quote is kept, so nothing ever disappears.
class CompositePriceSource implements StorePriceSource {
  final StorePriceSource _base;

  /// productId → chainId → kopecks.
  final Map<String, Map<String, int>> _live;

  const CompositePriceSource(this._base, this._live);

  static const _liveStores = {
    'novus': Store('novus', 'Novus'),
    'metro': Store('metro', 'METRO'),
    'auchan': Store('auchan', 'Auchan'),
    'atb': Store('atb', 'АТБ'),
    'silpo': Store('silpo', 'Сільпо'),
  };

  @override
  List<Store> get stores {
    final seen = <String>{};
    final out = <Store>[];
    for (final s in _base.stores) {
      if (seen.add(s.id)) out.add(_liveStores[s.id] ?? s);
    }
    // Live-only chains not present in the base catalog.
    final liveChains = <String>{
      for (final byChain in _live.values) ...byChain.keys,
    };
    for (final id in liveChains) {
      final store = _liveStores[id];
      if (store != null && seen.add(id)) out.add(store);
    }
    return out;
  }

  @override
  List<StoreQuote> quotesFor(String productId) {
    final baseQuotes = _base.quotesFor(productId);
    final live = _live[productId] ?? const {};
    final byStore = {for (final q in baseQuotes) q.store.id: q};

    final result = <StoreQuote>[
      // Chains we don't manage live pass straight through.
      for (final q in baseQuotes)
        if (!_liveStores.containsKey(q.store.id)) q,
    ];

    for (final storeId in _liveStores.keys) {
      final base = byStore[storeId];
      if (live.containsKey(storeId)) {
        result.add(StoreQuote(
          store: _liveStores[storeId]!,
          price: Money(live[storeId]!, currency: 'UAH'),
          packAmount:
              base?.packAmount ?? byStore['novus']?.packAmount ?? 1,
          packUnit:
              base?.packUnit ?? byStore['novus']?.packUnit ?? PortionUnit.pcs,
        ));
      } else if (base != null) {
        result.add(base); // no live price → keep the offline quote
      }
    }
    return result;
  }
}

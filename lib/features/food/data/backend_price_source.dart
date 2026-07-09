import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lifeos/core/config/backend_config.dart';

/// Client for the self-hosted АТБ/Сільпо price scraper. Sends the catalog
/// product ids and gets back `productId → chainId → kopecks` for the chains the
/// backend covers (`atb`, `silpo`). Pure `http`; a missing/unreachable backend
/// degrades gracefully to the offline catalog.
///
/// Expected response shape:
/// ```json
/// { "prices": { "eggs": { "atb": 5490, "silpo": 5990 }, "milk": { ... } } }
/// ```
class BackendPriceClient {
  final http.Client _http;
  final String baseUrl;

  BackendPriceClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? BackendConfig.pricesBackendUrl,
        _http = client ?? http.Client();

  bool get enabled => baseUrl.isNotEmpty;

  /// The chains this backend provides (АТБ/Сільпо — the ones zakaz.ua lacks).
  static const chains = ['atb', 'silpo'];

  Future<Map<String, Map<String, int>>> fetchAll(Set<String> productIds) async {
    if (!enabled || productIds.isEmpty) return const {};
    try {
      final uri = Uri.parse(
        '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/prices'
        '?ids=${productIds.map(Uri.encodeQueryComponent).join(',')}',
      );
      final res = await _http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return const {};
      return parsePrices(
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
      );
    } catch (_) {
      return const {}; // offline / backend down → offline catalog stays
    }
  }

  /// Parse the backend payload into `productId → chainId → kopecks`, keeping
  /// only positive integer prices for the known chains.
  static Map<String, Map<String, int>> parsePrices(Map<String, dynamic> body) {
    final prices = body['prices'];
    if (prices is! Map<String, dynamic>) return const {};
    final out = <String, Map<String, int>>{};
    for (final entry in prices.entries) {
      final byChain = entry.value;
      if (byChain is! Map<String, dynamic>) continue;
      final quotes = <String, int>{};
      for (final c in byChain.entries) {
        if (!chains.contains(c.key)) continue;
        final v = c.value;
        final kop = v is int ? v : (v is num ? v.round() : null);
        if (kop != null && kop > 0) quotes[c.key] = kop;
      }
      if (quotes.isNotEmpty) out[entry.key] = quotes;
    }
    return out;
  }
}

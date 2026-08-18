import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lifeos/features/food/domain/entities/nutrition.dart';

/// What a barcode turned out to be.
class ScannedProduct {
  final String barcode;
  final String name;

  /// Nutrition for 100 g / 100 ml, which is how packaging states it.
  final NutritionFacts per100;

  /// The serving the packet suggests, in grams, when it declares one.
  final int? servingG;

  const ScannedProduct({
    required this.barcode,
    required this.name,
    required this.per100,
    this.servingG,
  });

  /// Nutrition for [grams] of it.
  NutritionFacts forGrams(int grams) {
    final k = grams / 100;
    return NutritionFacts(
      kcal: (per100.kcal * k).round(),
      proteinG: (per100.proteinG * k).round(),
      fatG: (per100.fatG * k).round(),
      carbsG: (per100.carbsG * k).round(),
    );
  }
}

/// Why a lookup produced nothing — so the UI can say the true thing rather
/// than a generic failure.
enum LookupFailure {
  /// No network, or the service did not answer.
  offline,

  /// The service answered and does not know this barcode.
  unknown,

  /// Found, but without usable nutrition — worse than not found, because it
  /// would otherwise log a row of zeroes.
  noNutrition,
}

class LookupResult {
  final ScannedProduct? product;
  final LookupFailure? failure;
  const LookupResult.found(this.product) : failure = null;
  const LookupResult.failed(this.failure) : product = null;
}

/// Looks a barcode up in Open Food Facts.
///
/// Chosen because it is a genuinely open database: no account, no API key, no
/// quota, and the data is public. This is the **online** half of food logging —
/// the built-in dish catalogue keeps working with no network at all, and this
/// adds packaged goods when there is one.
class BarcodeFoodLookup {
  final http.Client _client;
  const BarcodeFoodLookup(this._client);

  static const _fields =
      'product_name,product_name_ru,product_name_uk,nutriments,serving_quantity';

  Future<LookupResult> find(String barcode, {String lang = 'en'}) async {
    final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json'
        '?fields=$_fields');
    try {
      final res = await _client.get(uri, headers: {
        // Open Food Facts asks callers to identify themselves so they can
        // contact whoever is misbehaving instead of blocking everyone.
        'User-Agent': 'Lumo/1.0 (personal life tracker)',
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode == 404) {
        return const LookupResult.failed(LookupFailure.unknown);
      }
      if (res.statusCode != 200) {
        return const LookupResult.failed(LookupFailure.offline);
      }
      return parse(res.body, barcode, lang: lang);
    } catch (_) {
      // No network, DNS failure, timeout — all the same to the user, who is
      // simply somewhere without signal.
      return const LookupResult.failed(LookupFailure.offline);
    }
  }

  /// Split out from the request so the parsing can be tested without a network.
  LookupResult parse(String body, String barcode, {String lang = 'en'}) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return const LookupResult.failed(LookupFailure.offline);
    }

    final status = json['status'];
    final product = json['product'];
    if (status == 0 || product is! Map<String, dynamic>) {
      return const LookupResult.failed(LookupFailure.unknown);
    }

    final name = _pickName(product, lang);
    if (name == null) {
      return const LookupResult.failed(LookupFailure.unknown);
    }

    final n = product['nutriments'];
    if (n is! Map<String, dynamic>) {
      return const LookupResult.failed(LookupFailure.noNutrition);
    }

    // Energy comes as kcal on most entries and only as kJ on some; converting
    // is better than showing a blank where a number belongs.
    var kcal = _num(n['energy-kcal_100g']);
    if (kcal == null) {
      final kj = _num(n['energy_100g']);
      if (kj != null) kcal = kj / 4.184;
    }
    if (kcal == null || kcal <= 0) {
      return const LookupResult.failed(LookupFailure.noNutrition);
    }

    return LookupResult.found(ScannedProduct(
      barcode: barcode,
      name: name,
      per100: NutritionFacts(
        kcal: kcal.round(),
        proteinG: (_num(n['proteins_100g']) ?? 0).round(),
        fatG: (_num(n['fat_100g']) ?? 0).round(),
        carbsG: (_num(n['carbohydrates_100g']) ?? 0).round(),
      ),
      servingG: _num(product['serving_quantity'])?.round(),
    ));
  }

  /// The name in the user's language when the database has one, falling back
  /// to the generic name. A Russian speaker should not be handed a Polish
  /// label just because it was listed first.
  String? _pickName(Map<String, dynamic> p, String lang) {
    for (final key in ['product_name_$lang', 'product_name']) {
      final v = p[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static double? _num(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

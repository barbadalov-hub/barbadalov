import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lifeos/features/food/data/barcode_food_lookup.dart';

void main() {
  final lookup = BarcodeFoodLookup(http.Client());

  LookupResult parse(String body, {String lang = 'en'}) =>
      lookup.parse(body, '4600000000000', lang: lang);

  test('reads name and nutrition off a normal answer', () {
    final r = parse('''
      {"status":1,"product":{
        "product_name":"Oat flakes",
        "nutriments":{"energy-kcal_100g":366,"proteins_100g":12.5,
                      "fat_100g":6.2,"carbohydrates_100g":62.1},
        "serving_quantity":40}}
    ''');

    final p = r.product!;
    expect(p.name, 'Oat flakes');
    expect(p.per100.kcal, 366);
    expect(p.per100.proteinG, 13, reason: 'rounded, not truncated');
    expect(p.servingG, 40);
  });

  test('a portion in grams is scaled off the per-100 figures', () {
    final p = parse('''
      {"status":1,"product":{"product_name":"X",
        "nutriments":{"energy-kcal_100g":400,"proteins_100g":20,
                      "fat_100g":10,"carbohydrates_100g":50}}}
    ''').product!;

    expect(p.forGrams(50).kcal, 200);
    expect(p.forGrams(50).proteinG, 10);
    expect(p.forGrams(200).carbsG, 100);
  });

  test('prefers the name in the user language', () {
    // A Russian speaker should not be handed the English label when the
    // database has a Russian one.
    final r = parse('''
      {"status":1,"product":{"product_name":"Buckwheat",
        "product_name_ru":"Гречка",
        "nutriments":{"energy-kcal_100g":330,"proteins_100g":12,
                      "fat_100g":3,"carbohydrates_100g":62}}}
    ''', lang: 'ru');
    expect(r.product!.name, 'Гречка');
  });

  test('converts kilojoules when kcal is missing', () {
    // Some entries only carry kJ; a blank where a number belongs is worse
    // than doing the division.
    final p = parse('''
      {"status":1,"product":{"product_name":"Y",
        "nutriments":{"energy_100g":1000,"proteins_100g":5,
                      "fat_100g":5,"carbohydrates_100g":5}}}
    ''').product!;
    expect(p.per100.kcal, 239);
  });

  group('what it refuses to invent', () {
    test('an unknown barcode is reported as unknown', () {
      expect(parse('{"status":0}').failure, LookupFailure.unknown);
    });

    test('a product with no nutrition is its own answer', () {
      // Logging this would add a row of zeroes to the day, which is worse than
      // saying nothing was found.
      final r = parse(
          '{"status":1,"product":{"product_name":"Z","nutriments":{}}}');
      expect(r.product, isNull);
      expect(r.failure, LookupFailure.noNutrition);
    });

    test('zero calories counts as no nutrition', () {
      final r = parse('''
        {"status":1,"product":{"product_name":"Z",
          "nutriments":{"energy-kcal_100g":0}}}
      ''');
      expect(r.failure, LookupFailure.noNutrition);
    });

    test('a nameless product is not logged as a blank line', () {
      final r = parse('''
        {"status":1,"product":{
          "nutriments":{"energy-kcal_100g":100}}}
      ''');
      expect(r.product, isNull);
    });

    test('a broken body never throws', () {
      expect(parse('not json at all').failure, LookupFailure.offline);
      expect(parse('').failure, LookupFailure.offline);
    });
  });

  test('numbers arriving as strings are still read', () {
    final p = parse('''
      {"status":1,"product":{"product_name":"S",
        "nutriments":{"energy-kcal_100g":"250","proteins_100g":"8"}}}
    ''').product!;
    expect(p.per100.kcal, 250);
    expect(p.per100.proteinG, 8);
  });
}

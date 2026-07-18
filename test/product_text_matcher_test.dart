import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/food/domain/product_text_matcher.dart';
import 'package:lifeos/features/food/domain/shelf_life_catalog.dart';

void main() {
  const m = ProductTextMatcher();

  test('matches common products across languages', () {
    expect(m.match('Свежее молоко 2.5%'), 'milk');
    expect(m.match('Хліб житній'), 'bread');
    expect(m.match('Chicken breast fillet'), 'chicken');
    expect(m.match('Яйця курячі С0'), 'eggs');
    expect(m.match('Банан'), 'banana');
    expect(m.match('Гречка ядриця'), 'buckwheat');
  });

  test('specific dairy wins over generic cheese', () {
    expect(m.match('Творог 5%'), 'cottage_cheese');
    expect(m.match('Сыр Фета'), 'feta');
    expect(m.match('Сир твердий 50%'), 'cheese');
  });

  test('returns null when nothing matches', () {
    expect(m.match('Стиральный порошок'), isNull);
    expect(m.match(''), isNull);
  });

  test('every matched id is a real known product (feeds shelf life & recipes)',
      () {
    for (final sample in [
      'молоко',
      'bread',
      'куриное филе',
      'яблоко',
      'рис басматі',
    ]) {
      final id = m.match(sample);
      expect(id, isNotNull, reason: sample);
      expect(knownProduct(id!), isNotNull, reason: 'unknown product $id');
    }
  });
}

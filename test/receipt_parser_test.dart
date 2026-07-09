import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/money/application/receipt_parser.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/shared/models/money.dart';

void main() {
  const parser = ReceiptParser();

  test('parses a messy Ukrainian grocery receipt', () {
    const text = '''
АТБ-маркет
Хліб Київський 1шт  18,50
Молоко 2,5% 2 x 21,50  43,00
Сир Голландський 0,350 x 250,00  87,50
Бензин А-95  15,20
Аптека вітамін С  55,00
СУМА ДО СПЛАТИ  219,20
ПДВ 20%  36,53
Дякуємо за покупку!
''';

    final r = parser.parse(text);

    // Five real items; the total, VAT and thank-you lines are not items.
    expect(r.items.length, 5);
    expect(r.detectedTotal, Money.fromMajor(219.20));
    // Item sum matches the printed total → confidence the parse is right.
    expect(r.computedTotal, Money.fromMajor(219.20));

    // Category guessing routed the spend correctly.
    final byCat = {for (final (c, m) in r.byCategory) c.id: m};
    expect(byCat[DefaultCategories.food.id], Money.fromMajor(149.00));
    expect(byCat[DefaultCategories.transport.id], Money.fromMajor(15.20));
    expect(byCat[DefaultCategories.health.id], Money.fromMajor(55.00));

    // Quantity captured from a "2 x 21,50" line.
    final milk = r.items.firstWhere((i) => i.name.contains('Молоко'));
    expect(milk.qty, 2);
  });

  test('empty / junk text yields no items', () {
    expect(parser.parse('').isEmpty, isTrue);
    expect(parser.parse('hello world\nthanks').isEmpty, isTrue);
  });

  test('handles a simple dot-decimal receipt with a TOTAL line', () {
    const text = '''
Coffee 3.50
Sandwich 5.00
TOTAL 8.50
''';
    final r = parser.parse(text);
    expect(r.items.length, 2);
    expect(r.total, Money.fromMajor(8.50));
  });
}

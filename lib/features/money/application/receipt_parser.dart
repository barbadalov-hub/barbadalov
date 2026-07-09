import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/receipt.dart';
import 'package:lifeos/shared/models/money.dart';

/// Turns raw receipt **text** (pasted, typed, or OCR'd elsewhere) into an
/// itemised, categorised breakdown — fully offline, no OCR plugin or API.
///
/// It is deliberately forgiving: real receipts are messy, so it extracts the
/// price as the last money-looking token on a line, treats a `2 x 15,00`
/// pattern as a quantity, skips fiscal/VAT/total noise, and guesses a category
/// from keywords. Anything it gets wrong the user can fix before saving.
class ReceiptParser {
  const ReceiptParser();

  // Keyword matching is **word-level** (exact word or stem-prefix), never a
  // raw substring — otherwise "ндс" (VAT) would match inside "голлаНДСький"
  // (cheese) and drop a real item.
  static final _wordSep = RegExp(r'[^0-9a-zа-яёіїєґ]+');

  /// Whole words that mark the receipt total line.
  static const _totalExact = {'total', 'sum'};
  static const _totalStems = [
    'сума', 'суму', 'суми', 'сумі', 'сплат', 'ітог', 'итог', 'разом',
    'всього', 'усього',
  ];
  static const _totalPhrases = ['to pay', 'amount due', 'до сплати', 'к оплате'];

  /// Whole words / stems that are fiscal or technical noise, never an item.
  static const _noiseExact = {
    'пдв', 'ндс', 'vat', 'рро', 'час', 'time', 'дата', 'date', 'чек', 'check',
    'каса', 'касса', 'fiscal',
  };
  static const _noiseStems = [
    'знижк', 'скидк', 'discount', 'фіскал', 'фискал', 'готівк', 'наличн',
    'касир', 'кассир', 'cashier', 'термінал', 'еквайр', 'эквайр', 'ідентиф',
    'дякуємо', 'дякую', 'спасибо', 'thank', 'баланс', 'бонус', 'решт',
    'сдача', 'change', 'акциз', 'касов',
  ];

  /// A money token: `42,90` / `42.9` / `42`. (Thousands separators are rare on
  /// retail receipts, so we keep this tight to avoid eating across columns.)
  static final _price = RegExp(r'(\d+[.,]\d{1,2}|\d+)');

  /// A `qty x unit` multiplier, e.g. `2 x 15,00` or `1,5 х 42.00`.
  static final _qtyMul =
      RegExp(r'(\d+(?:[.,]\d+)?)\s*[xх×*]\s*\d');

  ParsedReceipt parse(String raw) {
    final items = <ReceiptItem>[];
    Money? detectedTotal;

    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final isTotalLine =
          _match(line, _totalExact, _totalStems, _totalPhrases);
      if (isTotalLine) {
        final price = _lastPrice(line);
        // Keep the largest total seen (receipts often print "sub-total" too).
        if (price != null &&
            (detectedTotal == null || price > detectedTotal)) {
          detectedTotal = price;
        }
        continue;
      }

      if (_match(line, _noiseExact, _noiseStems, const [])) continue;

      final price = _lastPrice(line);
      if (price == null || !price.isPositive) continue;

      final name = _nameFrom(line);
      if (name.isEmpty) continue; // a bare number line — skip.

      final qty = _qtyFrom(line);
      items.add(ReceiptItem(
        name: name,
        qty: qty,
        price: price,
        categoryId: _guessCategory(name),
      ));
    }

    return ParsedReceipt(items: items, detectedTotal: detectedTotal);
  }

  /// Word-level keyword test: true if a phrase appears, or any word equals an
  /// [exact] keyword, or starts with a [stems] prefix.
  bool _match(
    String line,
    Set<String> exact,
    List<String> stems,
    List<String> phrases,
  ) {
    final low = line.toLowerCase();
    for (final p in phrases) {
      if (low.contains(p)) return true;
    }
    for (final word in low.split(_wordSep)) {
      if (word.isEmpty) continue;
      if (exact.contains(word)) return true;
      for (final s in stems) {
        if (word.startsWith(s)) return true;
      }
    }
    return false;
  }

  /// The last money token on a line, as [Money]; null if none.
  Money? _lastPrice(String line) {
    final matches = _price.allMatches(line).toList();
    if (matches.isEmpty) return null;
    return _toMoney(matches.last.group(0)!);
  }

  double _qtyFrom(String line) {
    final m = _qtyMul.firstMatch(line);
    if (m == null) return 1;
    return double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 1;
  }

  /// The product name = the leading text before the numeric price/qty region.
  String _nameFrom(String line) {
    final firstDigit = line.indexOf(RegExp(r'\d'));
    final head = (firstDigit <= 0 ? '' : line.substring(0, firstDigit)).trim();
    // Strip leading item numbers / bullets like "1." or "-".
    final cleaned = head.replaceAll(RegExp(r'^[\-•*\.\)\s]+'), '').trim();
    return cleaned;
  }

  Money _toMoney(String token) {
    final normalized = token.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
    final value = double.tryParse(normalized) ?? 0;
    return Money.fromMajor(value);
  }

  static const _keywords = <String, List<String>>{
    'expense_food': [
      'хліб', 'хлеб', 'молок', 'сир', 'сыр', 'яйц', 'яйця', 'м\'яс', 'мяс',
      'куриц', 'куряч', 'риба', 'рыба', 'овоч', 'овощ', 'фрукт', 'вода',
      'сік', 'сок', 'кав', 'коф', 'чай', 'цукор', 'сахар', 'борошн', 'мук',
      'макарон', 'олі', 'масл', 'йогурт', 'ковбас', 'колбас', 'сметан',
      'банан', 'яблук', 'яблок', 'помідор', 'томат', 'картопл', 'картоф',
      'bread', 'milk', 'cheese', 'egg', 'meat', 'chicken', 'fish', 'water',
      'juice', 'coffee', 'tea', 'sugar', 'flour', 'butter', 'yogurt',
    ],
    'expense_transport': [
      'бензин', 'пальне', 'палив', 'дизель', 'проїзд', 'проезд', 'метро',
      'таксі', 'такси', 'квиток', 'билет', 'fuel', 'petrol', 'diesel',
      'gas', 'uber', 'bolt', 'ticket',
    ],
    'expense_home': [
      'миюч', 'моющ', 'порош', 'папір', 'бумаг', 'серветк', 'салфет',
      'побутов', 'лампа', 'батарейк', 'мешки', 'пакет', 'мыло', 'мил',
      'shampoo', 'шампун', 'soap', 'paper', 'napkin', 'detergent',
    ],
    'expense_health': [
      'ліки', 'лекарств', 'таблет', 'вітамін', 'витамин', 'аптек', 'бинт',
      'маск', 'pharmac', 'vitamin', 'tablet', 'medic',
    ],
    'expense_fun': [
      'пив', 'вин', 'алког', 'горілк', 'водк', 'цигар', 'сигар', 'чіпс',
      'чипс', 'снек', 'шокол', 'цукерк', 'конфет', 'морозив', 'мороже',
      'beer', 'wine', 'snack', 'chocolate', 'candy', 'chips', 'cigar',
    ],
  };

  String _guessCategory(String name) {
    final n = name.toLowerCase();
    for (final entry in _keywords.entries) {
      for (final kw in entry.value) {
        if (n.contains(kw)) return entry.key;
      }
    }
    // Grocery receipts are food far more often than not — sensible default.
    return DefaultCategories.food.id;
  }
}

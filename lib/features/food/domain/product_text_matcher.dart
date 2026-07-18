/// Matches the text recognized on a product photo to a known catalog product
/// id (en/ru/uk keywords), so a scanned item lines up with its shelf life and
/// the "cook from your pantry" recipes. Pure — unit-tested.
library;

/// Ordered most-specific first, so "cottage cheese"/"feta" win over "cheese".
const List<(String id, List<String> keywords)> _catalog = [
  ('feta', ['feta', 'фета', 'брынза', 'бринза']),
  ('cottage_cheese', ['cottage', 'творог', 'творож', 'кисломолочн']),
  ('cheese', ['cheese', 'сыр', 'сир ', 'сир,']),
  ('yogurt', ['yogurt', 'yoghurt', 'йогурт']),
  ('kefir', ['kefir', 'кефир', 'кефір']),
  ('milk', ['milk', 'молоко', 'молок']),
  ('eggs', ['eggs', 'egg', 'яйц', 'яєц', 'яєч']),
  ('chicken', ['chicken', 'куриц', 'курин', 'курка', 'куряч']),
  ('turkey', ['turkey', 'индейк', 'індичк']),
  ('beef', ['beef', 'говядин', 'яловичин']),
  ('pork', ['pork', 'свинин']),
  ('salmon', ['salmon', 'лосос', 'семга', 'сьомга']),
  ('tuna', ['tuna', 'тунец', 'тунець']),
  ('shrimp', ['shrimp', 'prawn', 'кревет']),
  ('fish', ['fish', 'рыба', 'риба', 'филе рыб', 'філе риб']),
  ('tomatoes', ['tomato', 'помидор', 'помідор', 'томат']),
  ('cucumbers', ['cucumber', 'огур', 'огір']),
  ('bell_pepper', ['bell pepper', 'перец', 'перець', 'паприк']),
  ('zucchini', ['zucchini', 'кабач']),
  ('broccoli', ['broccoli', 'брокколи', 'броколі']),
  ('spinach', ['spinach', 'шпинат']),
  ('mushrooms', ['mushroom', 'гриб', 'шампинь', 'шампіньй', 'печериц']),
  ('carrots', ['carrot', 'морков', 'морква']),
  ('onion', ['onion', 'цибул', 'лук ']),
  ('potatoes', ['potato', 'картоф', 'картопл']),
  ('apple', ['apple', 'яблок', 'яблук']),
  ('banana', ['banana', 'банан']),
  ('berries', ['berry', 'berries', 'ягод', 'ягід', 'клубник', 'полуниц', 'малин', 'черник']),
  ('oats', ['oats', 'oatmeal', 'овсян', 'вівсян', 'геркулес']),
  ('flour', ['flour', 'мука', 'борошн']),
  ('buckwheat', ['buckwheat', 'гречк', 'гречн']),
  ('rice', ['rice', 'рис ', 'рис,', 'рис\n']),
  ('pasta', ['pasta', 'макарон', 'спагет', 'паста']),
  ('honey', ['honey', 'мёд', 'мед ', 'мед,', 'мед\n']),
  ('bread', ['bread', 'хлеб', 'хліб', 'батон', 'loaf']),
];

class ProductTextMatcher {
  const ProductTextMatcher();

  /// The catalog product id best matching [text], or null when nothing matches.
  String? match(String text) {
    final t = ' ${text.toLowerCase()} ';
    for (final (id, keywords) in _catalog) {
      for (final kw in keywords) {
        if (t.contains(kw)) return id;
      }
    }
    return null;
  }
}

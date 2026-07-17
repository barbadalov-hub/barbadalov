/// Known grocery products with a category emoji and a typical shelf life in
/// days. Lets the pantry auto-fill an expiry date instead of asking, and — via
/// the shared product ids (same as the meal & price catalogs) — lets the
/// "cook from your pantry" matcher line pantry items up with recipes.
/// Shelf lives are rough fridge/pantry defaults, not food-safety guarantees.
/// Pure — unit-tested.
class KnownProduct {
  final String id;
  final String emoji;
  final int shelfLifeDays;
  const KnownProduct(this.id, this.emoji, this.shelfLifeDays);

  /// i18n key for the product name (shared with the grocery list).
  String get nameKey => 'prod.$id';
}

const kKnownProducts = <KnownProduct>[
  // Bakery & short-life fresh.
  KnownProduct('bread', '🍞', 5),
  KnownProduct('milk', '🥛', 5),
  KnownProduct('yogurt', '🥛', 10),
  KnownProduct('kefir', '🥛', 10),
  KnownProduct('cottage_cheese', '🧀', 5),
  KnownProduct('cheese', '🧀', 14),
  KnownProduct('feta', '🧀', 14),
  KnownProduct('eggs', '🥚', 28),
  // Meat & fish (fresh).
  KnownProduct('chicken', '🍗', 3),
  KnownProduct('turkey', '🍗', 3),
  KnownProduct('beef', '🥩', 4),
  KnownProduct('pork', '🥩', 4),
  KnownProduct('fish', '🐟', 2),
  KnownProduct('salmon', '🐟', 2),
  KnownProduct('tuna', '🐟', 2),
  KnownProduct('shrimp', '🦐', 2),
  // Vegetables.
  KnownProduct('tomatoes', '🍅', 7),
  KnownProduct('cucumbers', '🥒', 7),
  KnownProduct('bell_pepper', '🫑', 7),
  KnownProduct('zucchini', '🥒', 7),
  KnownProduct('broccoli', '🥦', 5),
  KnownProduct('spinach', '🥬', 4),
  KnownProduct('mushrooms', '🍄', 5),
  KnownProduct('green_beans', '🫛', 5),
  KnownProduct('green_peas', '🫛', 5),
  KnownProduct('corn', '🌽', 4),
  KnownProduct('carrots', '🥕', 21),
  KnownProduct('beets', '🥕', 21),
  KnownProduct('onion', '🧅', 30),
  KnownProduct('potatoes', '🥔', 30),
  KnownProduct('sweet_potato', '🥔', 21),
  KnownProduct('pumpkin', '🎃', 30),
  KnownProduct('avocado', '🥑', 4),
  // Fruit.
  KnownProduct('apple', '🍎', 21),
  KnownProduct('banana', '🍌', 5),
  KnownProduct('berries', '🍓', 3),
  KnownProduct('watermelon', '🍉', 5),
  // Dry & pantry staples (long-lived).
  KnownProduct('oats', '🥣', 180),
  KnownProduct('flour', '🌾', 180),
  KnownProduct('rice', '🍚', 365),
  KnownProduct('buckwheat', '🌾', 365),
  KnownProduct('pasta', '🍝', 365),
  KnownProduct('couscous', '🌾', 365),
  KnownProduct('quinoa', '🌾', 365),
  KnownProduct('lentils', '🫘', 365),
  KnownProduct('beans', '🫘', 365),
  KnownProduct('chickpeas', '🫘', 365),
  KnownProduct('walnuts', '🌰', 180),
  KnownProduct('peanut_butter', '🥜', 180),
  KnownProduct('honey', '🍯', 730),
];

final Map<String, KnownProduct> _byId = {
  for (final p in kKnownProducts) p.id: p,
};

/// The catalog entry for [productId], or null when it isn't a known product.
KnownProduct? knownProduct(String productId) => _byId[productId];

/// Typical shelf life in days for [productId], or null when unknown.
int? shelfLifeDays(String productId) => _byId[productId]?.shelfLifeDays;

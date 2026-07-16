/// Which months (1-12) a product is in season — at its cheapest, freshest and
/// most local. Only clearly seasonal produce is listed; anything not here is
/// treated as available year-round (staples like eggs, milk, grains, meat).
///
/// Used to nudge the weekly menu toward seasonal ingredients (watermelon and
/// corn in summer, pumpkin and apples in autumn, cabbage in winter, …).
const kSeasonMonths = <String, Set<int>>{
  'watermelon': {7, 8, 9},
  'corn': {8, 9},
  'green_peas': {6, 7},
  'tomatoes': {7, 8, 9},
  'cucumbers': {6, 7, 8},
  'berries': {6, 7, 8},
  'zucchini': {7, 8, 9},
  'bell_pepper': {8, 9, 10},
  'pumpkin': {9, 10, 11},
  'apple': {9, 10, 11},
  'beets': {9, 10, 11},
  'cabbage': {10, 11, 12, 1},
  'spinach': {4, 5, 9, 10},
};

/// True when [productId] is in season in [month] (unlisted staples: always).
bool isInSeason(String productId, int month) {
  final months = kSeasonMonths[productId];
  return months == null || months.contains(month);
}

/// A dish's seasonality for [month]: +1 for each ingredient that is seasonal
/// produce currently *in* season, −1 for seasonal produce *out* of season.
/// Year-round staples don't count either way. Higher is more seasonal.
int seasonalScore(Iterable<String> productIds, int month) {
  var score = 0;
  for (final id in productIds) {
    final months = kSeasonMonths[id];
    if (months == null) continue; // year-round staple → neutral
    score += months.contains(month) ? 1 : -1;
  }
  return score;
}

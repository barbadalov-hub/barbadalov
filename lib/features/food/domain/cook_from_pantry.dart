import 'package:lifeos/features/food/domain/entities/nutrition.dart';

/// A meal ranked by how well the user's pantry covers its ingredients.
class PantryMeal {
  final MealOption meal;
  final int matched; // ingredients you already have
  final int total; // total ingredients
  final List<String> missingProductIds; // what you'd still need to buy
  final bool usesExpiring; // uses at least one soon-to-expire item

  const PantryMeal({
    required this.meal,
    required this.matched,
    required this.total,
    required this.missingProductIds,
    required this.usesExpiring,
  });

  /// Fraction of ingredients you already have (0..1).
  double get coverage => total == 0 ? 0 : matched / total;
}

/// Matches the meal catalog against the products a user actually has, so the
/// app can propose "cook this from what you've got" — balanced eating without
/// planning, and a way to use food up before it spoils. Pure — unit-tested.
class CookFromPantry {
  const CookFromPantry();

  /// Minimum share of a meal's ingredients you must already have for it to be
  /// worth suggesting.
  static const double minCoverage = 0.6;

  /// Ranks [meals] by pantry [available] product ids. Meals using an
  /// [expiring] product are surfaced first (use it up), then by coverage, then
  /// by fewest missing ingredients. Only meals meeting [minCoverage] (or fully
  /// covered) are returned. [limit] caps the result.
  List<PantryMeal> suggest({
    required Set<String> available,
    required List<MealOption> meals,
    Set<String> expiring = const {},
    int limit = 8,
  }) {
    final out = <PantryMeal>[];
    for (final m in meals) {
      if (m.ingredients.isEmpty) continue;
      final pm = describe(m, available, expiring);
      if (pm.coverage < minCoverage) continue;
      out.add(pm);
    }
    out.sort(byPreference);
    return out.length > limit ? out.sublist(0, limit) : out;
  }

  /// Describes how well [available] covers [meal]'s ingredients.
  PantryMeal describe(
      MealOption meal, Set<String> available, Set<String> expiring) {
    final missing = <String>[];
    var matched = 0;
    var usesExpiring = false;
    for (final ing in meal.ingredients) {
      if (available.contains(ing.productId)) {
        matched++;
        if (expiring.contains(ing.productId)) usesExpiring = true;
      } else {
        missing.add(ing.productId);
      }
    }
    return PantryMeal(
      meal: meal,
      matched: matched,
      total: meal.ingredients.length,
      missingProductIds: missing,
      usesExpiring: usesExpiring,
    );
  }

  /// Ranking: use-it-up meals first, then higher coverage, then fewer missing,
  /// then a stable id tiebreak.
  static int byPreference(PantryMeal a, PantryMeal b) {
    if (a.usesExpiring != b.usesExpiring) return a.usesExpiring ? -1 : 1;
    final c = b.coverage.compareTo(a.coverage);
    if (c != 0) return c;
    final mm = a.missingProductIds.length.compareTo(b.missingProductIds.length);
    if (mm != 0) return mm;
    return a.meal.id.compareTo(b.meal.id);
  }

  /// The single best dish to cook that uses [productId] (e.g. an item about to
  /// expire), given the pantry [available]. Highest ingredient coverage wins;
  /// null when no dish that uses it meets [minCoverage]. Used to turn an expiry
  /// alert into an actionable "cook X tonight" nudge.
  PantryMeal? bestUsing({
    required String productId,
    required Set<String> available,
    required List<MealOption> meals,
  }) {
    PantryMeal? best;
    for (final m in meals) {
      if (!m.ingredients.any((i) => i.productId == productId)) continue;
      final missing = <String>[];
      var matched = 0;
      for (final ing in m.ingredients) {
        if (available.contains(ing.productId)) {
          matched++;
        } else {
          missing.add(ing.productId);
        }
      }
      final coverage = matched / m.ingredients.length;
      if (coverage < minCoverage) continue;
      final pm = PantryMeal(
        meal: m,
        matched: matched,
        total: m.ingredients.length,
        missingProductIds: missing,
        usesExpiring: true,
      );
      if (best == null ||
          pm.coverage > best.coverage ||
          (pm.coverage == best.coverage &&
              m.id.compareTo(best.meal.id) < 0)) {
        best = pm;
      }
    }
    return best;
  }
}

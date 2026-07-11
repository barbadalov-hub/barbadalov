import 'package:lifeos/features/food/domain/entities/food_item.dart';

/// Small pure helper that answers "what should I use next?" for the pantry, so
/// food gets eaten before it spoils. Items without an expiry date are ignored
/// (they can't go to waste on a deadline).
class PantryPlanner {
  const PantryPlanner._();

  /// Pantry items that carry an expiry, soonest first (already-expired items,
  /// with the most-overdue first, sort ahead of everything). Ties break on name
  /// for a stable order.
  static List<FoodItem> byUrgency(List<FoodItem> items, DateTime now) {
    final dated = items.where((i) => i.expiry != null).toList()
      ..sort((a, b) {
        final da = a.daysUntilExpiry(now)!;
        final db = b.daysUntilExpiry(now)!;
        return da != db ? da.compareTo(db) : a.name.compareTo(b.name);
      });
    return dated;
  }

  /// The single item to eat next: the soonest-expiring item that is not already
  /// spoiled. Null when nothing has an upcoming expiry (all undated or expired).
  static FoodItem? useNext(List<FoodItem> items, DateTime now) {
    for (final item in byUrgency(items, now)) {
      if (!item.isExpired(now)) return item;
    }
    return null;
  }
}

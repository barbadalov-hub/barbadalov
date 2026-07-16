import 'dart:math' as math;

import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/domain/repositories/store_price_source.dart';
import 'package:lifeos/shared/models/money.dart';

/// One line of a consolidated weekly shopping list: how much of a product the
/// week's menu needs, how many standard packs that is, at which (cheapest)
/// store, and the cost.
class GroceryLine {
  final String productId;
  final int totalAmount; // summed ingredient amounts over the week
  final PortionUnit unit;
  final int packs;
  final Store store;
  final Money cost;

  const GroceryLine({
    required this.productId,
    required this.totalAmount,
    required this.unit,
    required this.packs,
    required this.store,
    required this.cost,
  });
}

/// A whole week's shopping list, most expensive line first, with the total.
class WeeklyGroceries {
  final List<GroceryLine> lines;
  const WeeklyGroceries(this.lines);

  Money get total => lines.fold(
      const Money.zero(currency: 'UAH'), (sum, l) => sum + l.cost);
}

/// Turns a week of meals into a single grocery list: sums the amount of each
/// product used across every meal, rounds up to whole packs, and picks the
/// cheapest store per product. Pure — unit-tested.
class WeeklyGroceryPlanner {
  final StorePriceSource _prices;
  const WeeklyGroceryPlanner(this._prices);

  WeeklyGroceries build(Iterable<MealOption> meals) {
    // productId → (total amount, unit)
    final needed = <String, (int, PortionUnit)>{};
    for (final meal in meals) {
      for (final ing in meal.ingredients) {
        final prev = needed[ing.productId];
        needed[ing.productId] =
            ((prev?.$1 ?? 0) + ing.amount, ing.unit);
      }
    }

    final lines = <GroceryLine>[];
    for (final entry in needed.entries) {
      final (amount, unit) = entry.value;
      GroceryLine? best;
      for (final q in _prices.quotesFor(entry.key)) {
        if (q.packAmount <= 0) continue;
        final packs = math.max(1, (amount / q.packAmount).ceil());
        final cost = Money(q.price.minorUnits * packs,
            currency: q.price.currency);
        if (best == null || cost < best.cost) {
          best = GroceryLine(
            productId: entry.key,
            totalAmount: amount,
            unit: unit,
            packs: packs,
            store: q.store,
            cost: cost,
          );
        }
      }
      if (best != null) lines.add(best);
    }

    lines.sort((a, b) => b.cost.minorUnits.compareTo(a.cost.minorUnits));
    return WeeklyGroceries(lines);
  }
}

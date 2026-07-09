import 'package:equatable/equatable.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/shared/models/money.dart';

/// One parsed line from a receipt: a product name, quantity, its line price and
/// a best-guess expense category.
class ReceiptItem extends Equatable {
  final String name;
  final double qty;
  final Money price;
  final String categoryId;

  const ReceiptItem({
    required this.name,
    required this.price,
    required this.categoryId,
    this.qty = 1,
  });

  ReceiptItem copyWith({String? categoryId, Money? price}) => ReceiptItem(
        name: name,
        qty: qty,
        price: price ?? this.price,
        categoryId: categoryId ?? this.categoryId,
      );

  @override
  List<Object?> get props => [name, qty, price, categoryId];
}

/// The result of analysing a receipt: the line items, the total the parser
/// read off the receipt (if any) and the total it computed by summing items.
class ParsedReceipt extends Equatable {
  final List<ReceiptItem> items;
  final Money? detectedTotal;

  const ParsedReceipt({required this.items, this.detectedTotal});

  Money get computedTotal =>
      items.fold(const Money.zero(), (sum, i) => sum + i.price);

  /// The most trustworthy total: what the receipt itself stated, else the sum.
  Money get total => detectedTotal ?? computedTotal;

  bool get isEmpty => items.isEmpty;

  /// Line-item totals grouped by category, largest first — the "what you spent
  /// it on" breakdown, ready to become one expense per category.
  List<(Category, Money)> get byCategory {
    final map = <String, int>{};
    for (final i in items) {
      map[i.categoryId] = (map[i.categoryId] ?? 0) + i.price.minorUnits;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in entries) (DefaultCategories.byId(e.key), Money(e.value)),
    ];
  }

  @override
  List<Object?> get props => [items, detectedTotal];
}

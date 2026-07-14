import 'package:equatable/equatable.dart';
import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/shared/models/money.dart';

/// A grocery chain.
class Store extends Equatable {
  final String id;
  final String name;
  const Store(this.id, this.name);

  @override
  List<Object?> get props => [id, name];
}

/// One store's price for a product's standard pack (e.g. eggs — 10 pcs).
class StoreQuote extends Equatable {
  final Store store;
  final Money price;
  final int packAmount;
  final PortionUnit packUnit;

  const StoreQuote({
    required this.store,
    required this.price,
    required this.packAmount,
    required this.packUnit,
  });

  @override
  List<Object?> get props => [store, price, packAmount, packUnit];
}

/// Port for grocery price data — same pattern as `DeviceHealthSource`.
///
/// The default implementation is a curated, fully offline catalog of
/// brand-free approximate prices; a different [StorePriceSource] can be swapped
/// in behind this interface without touching the UI.
abstract class StorePriceSource {
  List<Store> get stores;

  /// Quotes for a product across all known stores (may be empty).
  List<StoreQuote> quotesFor(String productId);
}

import 'dart:async';

import 'package:lifeos/features/money/domain/entities/transaction.dart';

/// Phase-1 persistence: an in-process store with a reactive stream. It keeps the
/// app fully runnable offline. Phase 3 replaces this class (only) with a
/// Firestore-backed source; nothing above the Data layer changes.
class MoneyLocalDataSource {
  final List<Transaction> _items;
  final StreamController<List<Transaction>> _controller;

  /// Called with the full list after every mutation so a provider can persist
  /// it. Kept as a callback so the data source stays free of storage concerns.
  final void Function(List<Transaction> items)? onChanged;

  MoneyLocalDataSource({List<Transaction> seed = const [], this.onChanged})
      : _items = List.of(seed),
        _controller = StreamController<List<Transaction>>.broadcast();

  List<Transaction> all() => List.unmodifiable(_items);

  List<Transaction> forMonth(int year, int month) => _items
      .where((t) => t.date.year == year && t.date.month == month)
      .toList(growable: false);

  void add(Transaction transaction) {
    _items.add(transaction);
    _emit();
    onChanged?.call(all());
  }

  void remove(String id) {
    _items.removeWhere((t) => t.id == id);
    _emit();
    onChanged?.call(all());
  }

  void update(Transaction transaction) {
    final i = _items.indexWhere((t) => t.id == transaction.id);
    if (i == -1) return;
    _items[i] = transaction;
    _emit();
    onChanged?.call(all());
  }

  /// Emits the current snapshot immediately, then every subsequent change.
  Stream<List<Transaction>> watch() async* {
    yield all();
    yield* _controller.stream;
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(all());
  }

  Future<void> dispose() => _controller.close();
}

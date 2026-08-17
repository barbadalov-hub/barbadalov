import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/services/doc_store.dart';
import 'package:lifeos/features/money/domain/entities/purchase.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:uuid/uuid.dart';

/// The kept purchases — the things whose receipts are worth holding on to.
class PurchaseController extends Notifier<List<Purchase>> {
  static const _key = 'purchases.list';
  static const _uuid = Uuid();

  @override
  List<Purchase> build() => ref.watch(jsonStoreProvider).loadList<Purchase>(
        _key,
        Purchase.fromJson,
        fallback: const [],
      );

  /// Adds a purchase, storing [receiptBytes] as its receipt when given.
  ///
  /// The photo is saved first: if the device refuses it, the purchase is still
  /// recorded without one, because a warranty date you typed in is worth
  /// keeping even when the picture failed.
  Future<Purchase> add({
    required String title,
    required Money price,
    required DateTime boughtAt,
    String shop = '',
    DateTime? until,
    CoverKind kind = CoverKind.warranty,
    String note = '',
    Uint8List? receiptBytes,
  }) async {
    final id = _uuid.v4();
    String? docId;
    if (receiptBytes != null) {
      docId = await docStore.save(id, receiptBytes);
    }

    final purchase = Purchase(
      id: id,
      title: title.trim(),
      shop: shop.trim(),
      price: price,
      boughtAt: boughtAt,
      until: until,
      kind: kind,
      receiptDocId: docId,
      note: note.trim(),
    );
    _persist([...state, purchase]);
    return purchase;
  }

  void update(Purchase next) {
    _persist([
      for (final p in state)
        if (p.id == next.id) next else p,
    ]);
  }

  /// Removes the record **and** its receipt file — an orphaned photo of a
  /// deleted purchase is just storage nobody can reach.
  Future<void> remove(String id) async {
    final gone = state.where((p) => p.id == id).toList();
    _persist(state.where((p) => p.id != id).toList());
    for (final p in gone) {
      if (p.receiptDocId != null) await docStore.delete(p.receiptDocId!);
    }
  }

  void _persist(List<Purchase> next) {
    ref
        .read(jsonStoreProvider)
        .saveList<Purchase>(_key, next, (p) => p.toJson());
    state = next;
  }
}

final purchasesProvider =
    NotifierProvider<PurchaseController, List<Purchase>>(
        PurchaseController.new);

/// Kept purchases, most urgent first.
final purchasesByUrgencyProvider = Provider<List<Purchase>>((ref) {
  final now = ref.watch(clockProvider).now();
  return sortByUrgency(ref.watch(purchasesProvider), now);
});

/// How many are inside their last month of cover — the badge worth showing,
/// because that is the only group where doing nothing costs something.
final endingSoonCountProvider = Provider<int>((ref) {
  final now = ref.watch(clockProvider).now();
  return ref
      .watch(purchasesProvider)
      .where((p) => p.state(now) == CoverState.endingSoon)
      .length;
});

/// Loads a stored receipt photo.
final receiptImageProvider =
    FutureProvider.family<Uint8List?, String>((ref, docId) async {
  return docStore.load(docId);
});

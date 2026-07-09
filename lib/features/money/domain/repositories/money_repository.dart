import 'package:lifeos/core/utils/result.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';

/// The contract the domain depends on. Phase 1 binds this to an in-memory
/// implementation; Phase 3 swaps in a Firestore-backed one — no caller changes.
abstract class MoneyRepository {
  /// Persist a transaction. Returns the stored entity on success.
  Future<Result<Transaction>> add(Transaction transaction);

  /// Delete a transaction by id.
  Future<Result<void>> remove(String id);

  /// Replace an existing transaction (matched by id).
  Future<Result<Transaction>> update(Transaction transaction);

  /// One-shot read of every transaction.
  Future<Result<List<Transaction>>> getAll();

  /// Transactions whose [Transaction.date] falls in the given month.
  Future<Result<List<Transaction>>> getForMonth(int year, int month);

  /// Reactive view of all transactions. Emits the current list immediately and
  /// again on every change, so budget/UI providers stay live.
  Stream<List<Transaction>> watchAll();
}

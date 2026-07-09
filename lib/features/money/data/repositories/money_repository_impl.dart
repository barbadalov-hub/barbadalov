import 'package:lifeos/core/errors/failures.dart';
import 'package:lifeos/core/utils/result.dart';
import 'package:lifeos/features/money/data/datasources/money_local_datasource.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/features/money/domain/repositories/money_repository.dart';

/// Binds the [MoneyRepository] contract to a concrete data source and maps any
/// low-level exception to a domain [Failure]. The rest of the app only ever
/// sees the interface.
class MoneyRepositoryImpl implements MoneyRepository {
  final MoneyLocalDataSource _local;

  const MoneyRepositoryImpl(this._local);

  @override
  Future<Result<Transaction>> add(Transaction transaction) async {
    try {
      _local.add(transaction);
      return Ok(transaction);
    } catch (e) {
      return Err(StorageFailure('Could not save transaction: $e'));
    }
  }

  @override
  Future<Result<void>> remove(String id) async {
    try {
      _local.remove(id);
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure('Could not delete transaction: $e'));
    }
  }

  @override
  Future<Result<Transaction>> update(Transaction transaction) async {
    try {
      _local.update(transaction);
      return Ok(transaction);
    } catch (e) {
      return Err(StorageFailure('Could not update transaction: $e'));
    }
  }

  @override
  Future<Result<List<Transaction>>> getAll() async {
    try {
      return Ok(_local.all());
    } catch (e) {
      return Err(StorageFailure('Could not read transactions: $e'));
    }
  }

  @override
  Future<Result<List<Transaction>>> getForMonth(int year, int month) async {
    try {
      return Ok(_local.forMonth(year, month));
    } catch (e) {
      return Err(StorageFailure('Could not read month: $e'));
    }
  }

  @override
  Stream<List<Transaction>> watchAll() => _local.watch();
}

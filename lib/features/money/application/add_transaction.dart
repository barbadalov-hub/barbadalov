import 'package:lifeos/core/errors/failures.dart';
import 'package:lifeos/core/events/event_bus.dart';
import 'package:lifeos/core/events/life_event.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/id_service.dart';
import 'package:lifeos/core/utils/result.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/features/money/domain/events/money_events.dart';
import 'package:lifeos/features/money/domain/repositories/money_repository.dart';
import 'package:lifeos/shared/models/money.dart';

/// Use case: record income or an expense.
///
/// This is the textbook LifeOS write path — validate → persist → **publish an
/// event**. Nothing mutates money state without an event travelling through the
/// [EventBus] to the [LifeCoreEngine].
class AddTransaction {
  final MoneyRepository _repository;
  final EventBus _eventBus;
  final IdService _idService;
  final Clock _clock;

  const AddTransaction(
    this._repository,
    this._eventBus,
    this._idService,
    this._clock,
  );

  Future<Result<Transaction>> call({
    required Money amount,
    required TransactionType type,
    required String categoryId,
    String note = '',
    DateTime? date,
    String userId = 'local',
  }) async {
    if (!amount.isPositive) {
      return const Err(ValidationFailure('Amount must be greater than zero.'));
    }

    final transaction = Transaction(
      id: _idService.newId(),
      amount: amount,
      type: type,
      categoryId: categoryId,
      note: note.trim(),
      date: date ?? _clock.now(),
    );

    final saved = await _repository.add(transaction);

    return saved.fold(
      Err.new,
      (stored) {
        _eventBus.publish(_eventFor(stored, userId));
        return Ok(stored);
      },
    );
  }

  ExpenseAddedEvent _expense(Transaction t, String userId) => ExpenseAddedEvent(
        id: _idService.newId(),
        userId: userId,
        occurredAt: _clock.now(),
        transaction: t,
      );

  IncomeAddedEvent _income(Transaction t, String userId) => IncomeAddedEvent(
        id: _idService.newId(),
        userId: userId,
        occurredAt: _clock.now(),
        transaction: t,
      );

  LifeEvent _eventFor(Transaction t, String userId) =>
      t.isIncome ? _income(t, userId) : _expense(t, userId);
}

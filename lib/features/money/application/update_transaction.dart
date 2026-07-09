import 'package:lifeos/core/errors/failures.dart';
import 'package:lifeos/core/events/event_bus.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/id_service.dart';
import 'package:lifeos/core/utils/result.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/features/money/domain/events/money_events.dart';
import 'package:lifeos/features/money/domain/repositories/money_repository.dart';

/// Use case: edit a transaction. Validate → persist → publish
/// [TransactionUpdatedEvent], so budget/AI/log all react like any change.
class UpdateTransaction {
  final MoneyRepository _repository;
  final EventBus _eventBus;
  final IdService _idService;
  final Clock _clock;

  const UpdateTransaction(
    this._repository,
    this._eventBus,
    this._idService,
    this._clock,
  );

  Future<Result<Transaction>> call(
    Transaction updated, {
    String userId = 'local',
  }) async {
    if (!updated.amount.isPositive) {
      return const Err(ValidationFailure('Amount must be greater than zero.'));
    }
    final result = await _repository.update(updated);
    return result.fold(
      Err.new,
      (stored) {
        _eventBus.publish(TransactionUpdatedEvent(
          id: _idService.newId(),
          userId: userId,
          occurredAt: _clock.now(),
          transaction: stored,
        ));
        return Ok(stored);
      },
    );
  }
}

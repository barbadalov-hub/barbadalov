import 'package:lifeos/core/events/event_bus.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/id_service.dart';
import 'package:lifeos/core/utils/result.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/features/money/domain/events/money_events.dart';
import 'package:lifeos/features/money/domain/repositories/money_repository.dart';

/// Use case: delete a transaction. Same write-path shape as every mutation —
/// persist, then publish a [TransactionRemovedEvent] through the EventBus so
/// the budget, AI and event log all react.
class RemoveTransaction {
  final MoneyRepository _repository;
  final EventBus _eventBus;
  final IdService _idService;
  final Clock _clock;

  const RemoveTransaction(
    this._repository,
    this._eventBus,
    this._idService,
    this._clock,
  );

  Future<Result<void>> call(
    Transaction transaction, {
    String userId = 'local',
  }) async {
    final result = await _repository.remove(transaction.id);
    return result.fold<Result<void>>(
      Err.new,
      (_) {
        _eventBus.publish(TransactionRemovedEvent(
          id: _idService.newId(),
          userId: userId,
          occurredAt: _clock.now(),
          transaction: transaction,
        ));
        return const Ok(null);
      },
    );
  }
}

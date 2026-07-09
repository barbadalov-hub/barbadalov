import 'package:lifeos/core/events/life_event.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';

/// Machine names for MoneyOS events (persisted to the `events/` log).
class MoneyEventType {
  const MoneyEventType._();
  static const expenseAdded = 'expense_added';
  static const incomeAdded = 'income_added';
  static const transactionRemoved = 'transaction_removed';
  static const transactionUpdated = 'transaction_updated';
}

/// Emitted after a transaction is edited.
class TransactionUpdatedEvent extends LifeEvent {
  final Transaction transaction;

  const TransactionUpdatedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required this.transaction,
  });

  @override
  String get type => MoneyEventType.transactionUpdated;

  @override
  Map<String, dynamic> toPayload() => {
        'transactionId': transaction.id,
        'amountMinorUnits': transaction.amount.minorUnits,
        'currency': transaction.amount.currency,
        'categoryId': transaction.categoryId,
        'transactionType': transaction.type.name,
      };
}

/// Emitted after a transaction is deleted.
class TransactionRemovedEvent extends LifeEvent {
  final Transaction transaction;

  const TransactionRemovedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required this.transaction,
  });

  @override
  String get type => MoneyEventType.transactionRemoved;

  @override
  Map<String, dynamic> toPayload() => {
        'transactionId': transaction.id,
        'amountMinorUnits': transaction.amount.minorUnits,
        'currency': transaction.amount.currency,
        'categoryId': transaction.categoryId,
        'transactionType': transaction.type.name,
      };
}

/// Emitted after an expense is durably recorded.
class ExpenseAddedEvent extends LifeEvent {
  final Transaction transaction;

  const ExpenseAddedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required this.transaction,
  });

  @override
  String get type => MoneyEventType.expenseAdded;

  @override
  Map<String, dynamic> toPayload() => {
        'transactionId': transaction.id,
        'amountMinorUnits': transaction.amount.minorUnits,
        'currency': transaction.amount.currency,
        'categoryId': transaction.categoryId,
        'note': transaction.note,
        'date': transaction.date.toIso8601String(),
      };
}

/// Emitted after income is durably recorded.
class IncomeAddedEvent extends LifeEvent {
  final Transaction transaction;

  const IncomeAddedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required this.transaction,
  });

  @override
  String get type => MoneyEventType.incomeAdded;

  @override
  Map<String, dynamic> toPayload() => {
        'transactionId': transaction.id,
        'amountMinorUnits': transaction.amount.minorUnits,
        'currency': transaction.amount.currency,
        'categoryId': transaction.categoryId,
        'note': transaction.note,
        'date': transaction.date.toIso8601String(),
      };
}

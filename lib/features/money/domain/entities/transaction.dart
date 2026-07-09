import 'package:equatable/equatable.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/shared/models/money.dart';

/// A single money movement. [amount] is always a positive magnitude; direction
/// is carried by [type]. Use [signedMinorUnits] when summing a mixed list.
class Transaction extends Equatable {
  final String id;
  final Money amount;
  final TransactionType type;
  final String categoryId;
  final String note;
  final DateTime date;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note = '',
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  Category get category => DefaultCategories.byId(categoryId);

  /// Positive for income, negative for expense — the natural sum contribution.
  int get signedMinorUnits => isIncome ? amount.minorUnits : -amount.minorUnits;

  Map<String, dynamic> toJson() => {
        'id': id,
        'minorUnits': amount.minorUnits,
        'currency': amount.currency,
        'type': type.name,
        'categoryId': categoryId,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        amount: Money(
          json['minorUnits'] as int,
          currency: json['currency'] as String,
        ),
        type: TransactionType.values.byName(json['type'] as String),
        categoryId: json['categoryId'] as String,
        note: (json['note'] as String?) ?? '',
        date: DateTime.parse(json['date'] as String),
      );

  @override
  List<Object?> get props => [id, amount, type, categoryId, note, date];
}

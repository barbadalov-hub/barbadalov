import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/money/application/transaction_csv.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/shared/models/money.dart';

void main() {
  test('builds a header + newest-first rows and escapes notes', () {
    final txs = [
      Transaction(
        id: '1',
        amount: Money.fromMajor(12.5),
        type: TransactionType.expense,
        categoryId: DefaultCategories.food.id,
        date: DateTime(2026, 7, 1),
        note: 'lunch, tasty',
      ),
      Transaction(
        id: '2',
        amount: Money.fromMajor(3200),
        type: TransactionType.income,
        categoryId: DefaultCategories.salary.id,
        date: DateTime(2026, 7, 3),
      ),
    ];

    final csv = buildTransactionsCsv(txs);
    final lines = csv.split('\r\n');

    expect(lines.first, 'Date,Type,Category,Amount,Currency,Note');
    // Newest first: the July 3 salary row precedes the July 1 lunch.
    expect(lines[1], contains('2026-07-03'));
    expect(lines[1], contains('income'));
    expect(lines[1], contains('3200.00'));
    // Note with a comma is quoted.
    expect(lines[2], contains('"lunch, tasty"'));
  });
}

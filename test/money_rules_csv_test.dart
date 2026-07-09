import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/money/application/transaction_csv.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/category_rule.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/shared/models/money.dart';

void main() {
  group('CategoryRuleMatcher', () {
    const m = CategoryRuleMatcher();
    final rules = [
      const CategoryRule(id: '1', keyword: 'atb', categoryId: 'expense_food'),
      const CategoryRule(
          id: '2', keyword: 'netflix', categoryId: 'expense_fun'),
      const CategoryRule(
          id: '3', keyword: 'atb супермаркет', categoryId: 'expense_home'),
    ];

    test('matches case-insensitively; longest keyword wins', () {
      expect(m.categoryFor('чек ATB супермаркет №5', rules), 'expense_home');
      expect(m.categoryFor('оплата ATB', rules), 'expense_food');
      expect(m.categoryFor('NETFLIX subscription', rules), 'expense_fun');
    });

    test('no match returns null', () {
      expect(m.categoryFor('random shop', rules), isNull);
    });
  });

  group('parseTransactionsCsv', () {
    test('round-trips our own export and skips header/junk', () {
      final csv = buildTransactionsCsv([
        Transaction(
          id: '1',
          amount: const Money(1250),
          type: TransactionType.expense,
          categoryId: DefaultCategories.food.id,
          date: DateTime(2026, 7, 1),
          note: 'lunch, tasty',
        ),
        Transaction(
          id: '2',
          amount: const Money(320000),
          type: TransactionType.income,
          categoryId: DefaultCategories.salary.id,
          date: DateTime(2026, 7, 3),
        ),
      ]);

      final rows = parseTransactionsCsv('$csv\n\ngarbage,row');
      expect(rows.length, 2);
      // Newest first from the builder → salary income first.
      expect(rows.first.type, TransactionType.income);
      expect(rows.first.amountMinor, 320000);
      // Quoted note with a comma survives.
      final lunch = rows.firstWhere((r) => r.type == TransactionType.expense);
      expect(lunch.note, 'lunch, tasty');
      expect(lunch.amountMinor, 1250);
    });

    test('categoryIdForName maps names back to ids', () {
      expect(categoryIdForName('Food'), DefaultCategories.food.id);
      expect(categoryIdForName('SALARY'), DefaultCategories.salary.id);
      expect(categoryIdForName('nonsense'), isNull);
    });
  });
}

import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

/// A spending or income category. Phase 1 ships a fixed default set; a later
/// phase lets users create and budget per category.
class Category extends Equatable {
  final String id;
  final String name;
  final String emoji;
  final TransactionType type;

  const Category({
    required this.id,
    required this.name,
    required this.emoji,
    required this.type,
  });

  @override
  List<Object?> get props => [id, name, emoji, type];
}

/// Built-in categories. Ids are stable strings so they survive persistence.
class DefaultCategories {
  const DefaultCategories._();

  static const salary = Category(
    id: 'income_salary',
    name: 'Salary',
    emoji: '💼',
    type: TransactionType.income,
  );
  static const otherIncome = Category(
    id: 'income_other',
    name: 'Other income',
    emoji: '💰',
    type: TransactionType.income,
  );

  static const food = Category(
    id: 'expense_food',
    name: 'Food',
    emoji: '🥗',
    type: TransactionType.expense,
  );
  static const transport = Category(
    id: 'expense_transport',
    name: 'Transport',
    emoji: '🚗',
    type: TransactionType.expense,
  );
  static const home = Category(
    id: 'expense_home',
    name: 'Home',
    emoji: '🏠',
    type: TransactionType.expense,
  );
  static const fun = Category(
    id: 'expense_fun',
    name: 'Fun',
    emoji: '🎉',
    type: TransactionType.expense,
  );
  static const health = Category(
    id: 'expense_health',
    name: 'Health',
    emoji: '❤️',
    type: TransactionType.expense,
  );
  static const other = Category(
    id: 'expense_other',
    name: 'Other',
    emoji: '🧾',
    type: TransactionType.expense,
  );

  static const all = <Category>[
    salary,
    otherIncome,
    food,
    transport,
    home,
    fun,
    health,
    other,
  ];

  static Category byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => other);

  static List<Category> of(TransactionType type) =>
      all.where((c) => c.type == type).toList();
}

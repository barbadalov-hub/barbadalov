import 'package:equatable/equatable.dart';

/// A user rule: when a transaction's text contains [keyword], categorize it as
/// [categoryId]. Applied to receipts and CSV imports so categories fill in
/// automatically (à la Firefly III rules).
class CategoryRule extends Equatable {
  final String id;
  final String keyword;
  final String categoryId;

  const CategoryRule({
    required this.id,
    required this.keyword,
    required this.categoryId,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'keyword': keyword, 'categoryId': categoryId};

  factory CategoryRule.fromJson(Map<String, dynamic> j) => CategoryRule(
        id: j['id'] as String,
        keyword: (j['keyword'] as String?) ?? '',
        categoryId: (j['categoryId'] as String?) ?? 'expense_other',
      );

  @override
  List<Object?> get props => [id, keyword, categoryId];
}

/// Pure matcher: the first rule whose keyword appears (case-insensitive) in the
/// text, or null. Longer keywords win so specific rules beat generic ones.
class CategoryRuleMatcher {
  const CategoryRuleMatcher();

  String? categoryFor(String text, List<CategoryRule> rules) {
    final low = text.toLowerCase();
    final sorted = [...rules]
      ..sort((a, b) => b.keyword.length.compareTo(a.keyword.length));
    for (final r in sorted) {
      final k = r.keyword.trim().toLowerCase();
      if (k.isNotEmpty && low.contains(k)) return r.categoryId;
    }
    return null;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/money/domain/entities/category_rule.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:uuid/uuid.dart';

/// Persisted auto-categorization rules.
class CategoryRulesController extends Notifier<List<CategoryRule>> {
  static const _key = 'money.categoryRules';
  static const _uuid = Uuid();

  @override
  List<CategoryRule> build() =>
      ref.watch(jsonStoreProvider).loadList<CategoryRule>(
            _key,
            CategoryRule.fromJson,
            fallback: const [],
          );

  void add(String keyword, String categoryId) {
    if (keyword.trim().isEmpty) return;
    _persist([
      ...state,
      CategoryRule(id: _uuid.v4(), keyword: keyword.trim(), categoryId: categoryId),
    ]);
  }

  void remove(String id) =>
      _persist([for (final r in state) if (r.id != id) r]);

  void _persist(List<CategoryRule> next) {
    ref.read(jsonStoreProvider).saveList<CategoryRule>(
          _key,
          next,
          (r) => r.toJson(),
        );
    state = next;
  }
}

final categoryRulesProvider =
    NotifierProvider<CategoryRulesController, List<CategoryRule>>(
        CategoryRulesController.new);

/// Resolves the category a piece of text should map to via the user's rules, or
/// null if nothing matches.
final categorizeProvider = Provider<String? Function(String)>((ref) {
  final rules = ref.watch(categoryRulesProvider);
  return (text) => const CategoryRuleMatcher().categoryFor(text, rules);
});

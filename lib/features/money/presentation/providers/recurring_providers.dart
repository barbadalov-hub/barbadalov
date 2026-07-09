import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/recurring_rule.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:uuid/uuid.dart';

/// Stored recurring rules, sorted by day of month.
class RecurringController extends Notifier<List<RecurringRule>> {
  static const _key = 'money.recurring';
  static const _uuid = Uuid();

  @override
  List<RecurringRule> build() {
    final list = [
      ...ref.watch(jsonStoreProvider).loadList<RecurringRule>(
            _key,
            RecurringRule.fromJson,
            fallback: const [],
          ),
    ]..sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
    return list;
  }

  void add(RecurringRule rule) =>
      _persist([...state, rule.copyWith()]..sort(
          (a, b) => a.dayOfMonth.compareTo(b.dayOfMonth)));

  void addNew({
    required String label,
    required TransactionType type,
    required int amountMinor,
    required String categoryId,
    required int dayOfMonth,
  }) {
    add(RecurringRule(
      id: _uuid.v4(),
      label: label,
      type: type,
      amountMinor: amountMinor,
      categoryId: categoryId,
      dayOfMonth: dayOfMonth,
    ));
  }

  void toggle(String id) => _persist([
        for (final r in state)
          if (r.id == id) r.copyWith(active: !r.active) else r,
      ]);

  void remove(String id) =>
      _persist([for (final r in state) if (r.id != id) r]);

  void markRun(String id, String yearMonth) => _persist([
        for (final r in state)
          if (r.id == id) r.copyWith(lastRun: yearMonth) else r,
      ]);

  void _persist(List<RecurringRule> next) {
    ref.read(jsonStoreProvider).saveList<RecurringRule>(
          _key,
          next,
          (r) => r.toJson(),
        );
    state = next;
  }
}

final recurringProvider =
    NotifierProvider<RecurringController, List<RecurringRule>>(
        RecurringController.new);

/// Materialises any due recurring rules into real transactions. Runs once per
/// session (kept alive by [HomeShell]); a rule fires at most once per month,
/// on/after its day, dated to that day.
final recurringMaterializerProvider = Provider<void>((ref) {
  Future.microtask(() {
    try {
      _materialize(ref);
    } catch (_) {}
  });
});

void _materialize(Ref ref) {
  final now = ref.read(clockProvider).now();
  final ym = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  final rules = ref.read(recurringProvider);
  final add = ref.read(addTransactionProvider);
  final ctrl = ref.read(recurringProvider.notifier);

  for (final r in rules) {
    if (!r.active || r.lastRun == ym) continue;
    if (now.day < r.dayOfMonth) continue; // not due yet this month
    final day = r.dayOfMonth.clamp(1, _daysInMonth(now.year, now.month));
    add.call(
      amount: r.amount,
      type: r.type,
      categoryId: r.categoryId,
      note: r.label,
      date: DateTime(now.year, now.month, day),
    );
    ctrl.markRun(r.id, ym);
  }
}

int _daysInMonth(int year, int month) =>
    DateTime(year, month + 1, 0).day;

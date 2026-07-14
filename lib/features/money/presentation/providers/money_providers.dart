import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/constants/app_constants.dart';
import 'package:lifeos/features/money/application/add_transaction.dart';
import 'package:lifeos/features/money/application/compute_budget.dart';
import 'package:lifeos/features/money/application/finance_tips.dart';
import 'package:lifeos/features/money/application/remove_transaction.dart';
import 'package:lifeos/features/goals/presentation/providers/goal_providers.dart';
import 'package:lifeos/features/money/application/spending_analyzer.dart';
import 'package:lifeos/features/money/application/update_transaction.dart';
import 'package:lifeos/features/money/data/datasources/money_local_datasource.dart';
import 'package:lifeos/features/money/data/repositories/money_repository_impl.dart';
import 'package:lifeos/features/money/domain/entities/budget.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/features/money/domain/repositories/money_repository.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// MoneyOS composition root.

/// In-memory store seeded with a realistic current month so the app has
/// something to show on first launch. Swap this provider's body for a Firestore
/// data source in Phase 3 — nothing else changes.
final moneyLocalDataSourceProvider = Provider<MoneyLocalDataSource>((ref) {
  final now = ref.watch(clockProvider).now();
  final store = ref.watch(jsonStoreProvider);
  const key = 'money.transactions';
  final source = MoneyLocalDataSource(
    seed: store.loadList(
      key,
      Transaction.fromJson,
      fallback:
          AppConstants.seedDemoData ? _seedForMonth(now) : const <Transaction>[],
    ),
    onChanged: (items) => store.saveList(key, items, (t) => t.toJson()),
  );
  ref.onDispose(source.dispose);
  return source;
});

final moneyRepositoryProvider = Provider<MoneyRepository>((ref) {
  return MoneyRepositoryImpl(ref.watch(moneyLocalDataSourceProvider));
});

final addTransactionProvider = Provider<AddTransaction>((ref) {
  return AddTransaction(
    ref.watch(moneyRepositoryProvider),
    ref.watch(eventBusProvider),
    ref.watch(idServiceProvider),
    ref.watch(clockProvider),
  );
});

final updateTransactionProvider = Provider<UpdateTransaction>((ref) {
  return UpdateTransaction(
    ref.watch(moneyRepositoryProvider),
    ref.watch(eventBusProvider),
    ref.watch(idServiceProvider),
    ref.watch(clockProvider),
  );
});

final removeTransactionProvider = Provider<RemoveTransaction>((ref) {
  return RemoveTransaction(
    ref.watch(moneyRepositoryProvider),
    ref.watch(eventBusProvider),
    ref.watch(idServiceProvider),
    ref.watch(clockProvider),
  );
});

final computeBudgetProvider = Provider<ComputeBudget>((ref) {
  return ComputeBudget(ref.watch(clockProvider));
});

/// Reactive list of every transaction. Rebuilds whenever a new one is added.
final transactionsProvider = StreamProvider<List<Transaction>>((ref) {
  // Touch the engine so the event pipeline is running before writes happen.
  ref.watch(coreEngineProvider);
  return ref.watch(moneyRepositoryProvider).watchAll();
});

/// The current-month [Budget], recomputed from the live transaction stream.
final currentBudgetProvider = Provider<Budget>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? const [];
  final now = ref.watch(clockProvider).now();
  final monthTx = transactions
      .where((t) => t.date.year == now.year && t.date.month == now.month)
      .toList(growable: false);
  return ref.watch(computeBudgetProvider).call(monthTx, at: now);
});

/// The evergreen finance tip of the day (i18n key), for the Money screen.
final financeTipProvider = Provider<String>(
    (ref) => FinanceTips.ofDay(ref.watch(clockProvider).now()));

// --- Search & filter for the transaction history ---------------------------
final txQueryProvider = StateProvider<String>((ref) => '');
final txTypeFilterProvider = StateProvider<TransactionType?>((ref) => null);

/// Daily expense totals (day-of-month → minor units) for the current month —
/// powers the spending calendar heatmap.
final dailySpendingProvider = Provider<Map<int, int>>((ref) {
  final now = ref.watch(clockProvider).now();
  final list = ref.watch(transactionsProvider).valueOrNull ?? const [];
  final out = <int, int>{};
  for (final t in list) {
    if (t.isExpense && t.date.year == now.year && t.date.month == now.month) {
      out[t.date.day] = (out[t.date.day] ?? 0) + t.amount.minorUnits;
    }
  }
  return out;
});

/// This-month vs last-month spending, with the category that moved the most.
class MonthComparison {
  final int thisSpent;
  final int lastSpent;
  final String? topMoverCategory;
  final int topMoverDelta; // signed (this − last)
  const MonthComparison({
    required this.thisSpent,
    required this.lastSpent,
    this.topMoverCategory,
    this.topMoverDelta = 0,
  });

  bool get hasLast => lastSpent > 0;
  int get delta => thisSpent - lastSpent;
  int? get pctChange =>
      lastSpent == 0 ? null : (delta * 100 / lastSpent).round();
}

final monthComparisonProvider = Provider<MonthComparison>((ref) {
  final now = ref.watch(clockProvider).now();
  final list = ref.watch(transactionsProvider).valueOrNull ?? const [];
  final lastMonth = DateTime(now.year, now.month - 1);

  var thisSpent = 0;
  var lastSpent = 0;
  final thisCat = <String, int>{};
  final lastCat = <String, int>{};
  for (final t in list) {
    if (!t.isExpense) continue;
    if (t.date.year == now.year && t.date.month == now.month) {
      thisSpent += t.amount.minorUnits;
      thisCat[t.categoryId] = (thisCat[t.categoryId] ?? 0) + t.amount.minorUnits;
    } else if (t.date.year == lastMonth.year &&
        t.date.month == lastMonth.month) {
      lastSpent += t.amount.minorUnits;
      lastCat[t.categoryId] = (lastCat[t.categoryId] ?? 0) + t.amount.minorUnits;
    }
  }

  String? mover;
  var moverDelta = 0;
  for (final cat in {...thisCat.keys, ...lastCat.keys}) {
    final d = (thisCat[cat] ?? 0) - (lastCat[cat] ?? 0);
    if (d.abs() > moverDelta.abs()) {
      moverDelta = d;
      mover = cat;
    }
  }

  return MonthComparison(
    thisSpent: thisSpent,
    lastSpent: lastSpent,
    topMoverCategory: mover,
    topMoverDelta: moverDelta,
  );
});

/// "Smart finance": live pace/projection/cut/goal-impact observations.
final smartFinanceProvider = Provider<List<FinanceInsight>>((ref) {
  final now = ref.watch(clockProvider).now();
  final all = ref.watch(transactionsProvider).valueOrNull ?? const [];
  final monthTx = all
      .where((t) => t.date.year == now.year && t.date.month == now.month)
      .toList(growable: false);
  return const SpendingAnalyzer().analyze(
    budget: ref.watch(currentBudgetProvider),
    monthTransactions: monthTx,
    goals: ref.watch(goalsProvider).valueOrNull ?? const [],
    now: now,
  );
});

/// This month's expenses grouped by category, largest first (the classic
/// open-source finance-app breakdown, à la Ivy Wallet).
final categorySpendingProvider = Provider<List<(Category, Money)>>((ref) {
  final now = ref.watch(clockProvider).now();
  final list = ref.watch(transactionsProvider).valueOrNull ?? const [];
  final byCategory = <String, int>{};
  for (final t in list) {
    if (t.isExpense && t.date.year == now.year && t.date.month == now.month) {
      byCategory[t.categoryId] =
          (byCategory[t.categoryId] ?? 0) + t.amount.minorUnits;
    }
  }
  final entries = byCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final e in entries) (DefaultCategories.byId(e.key), Money(e.value)),
  ];
});

/// Income vs expenses for the last 6 months, oldest first:
/// (monthStart, incomeMinor, expenseMinor).
final monthlySeriesProvider = Provider<List<(DateTime, int, int)>>((ref) {
  final now = ref.watch(clockProvider).now();
  final list = ref.watch(transactionsProvider).valueOrNull ?? const [];
  final series = <(DateTime, int, int)>[];
  for (var back = 5; back >= 0; back--) {
    final month = DateTime(now.year, now.month - back);
    var income = 0;
    var expense = 0;
    for (final t in list) {
      if (t.date.year == month.year && t.date.month == month.month) {
        if (t.isIncome) {
          income += t.amount.minorUnits;
        } else {
          expense += t.amount.minorUnits;
        }
      }
    }
    series.add((month, income, expense));
  }
  return series;
});

/// Seed data: one salary + a handful of expenses spread across the month.
List<Transaction> _seedForMonth(DateTime now) {
  Transaction tx(int day, int major, TransactionType type, Category c) =>
      Transaction(
        id: 'seed_${type.name}_${c.id}_$day',
        amount: Money.fromMajor(major),
        type: type,
        categoryId: c.id,
        date: DateTime(now.year, now.month, day.clamp(1, now.day).toInt()),
      );

  return [
    tx(1, 3200, TransactionType.income, DefaultCategories.salary),
    tx(2, 45, TransactionType.expense, DefaultCategories.food),
    tx(3, 60, TransactionType.expense, DefaultCategories.transport),
    tx(5, 900, TransactionType.expense, DefaultCategories.home),
    tx(6, 30, TransactionType.expense, DefaultCategories.fun),
    tx(8, 55, TransactionType.expense, DefaultCategories.food),
  ];
}

/// Convenience for the reserve rule label shown in the UI (e.g. "15%").
String reserveRateLabel(double rate) =>
    '${(rate * 100).round()}% (${(AppConstants.minReserveRate * 100).round()}–'
    '${(AppConstants.maxReserveRate * 100).round()}%)';

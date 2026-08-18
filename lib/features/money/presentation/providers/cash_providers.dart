import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/money/domain/cash_position.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/features/money/presentation/providers/recurring_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// The user's statement of what they actually have, and when they said it.
///
/// Nothing is assumed on the user's behalf: until they state a balance the app
/// reports that it does not know, rather than inventing one out of whichever
/// transactions it happens to have seen.
class BalanceAnchorController extends Notifier<BalanceAnchor?> {
  static const _key = 'money.balanceAnchor';

  @override
  BalanceAnchor? build() {
    final raw = ref.watch(keyValueStoreProvider).getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return BalanceAnchor.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Record what the user has right now. Re-stating it is a reconciliation:
  /// the new figure supersedes everything before it, which is what lets cash
  /// spent without logging drift back out of the balance.
  void record(Money amount) {
    final anchor =
        BalanceAnchor(amount: amount, on: ref.read(clockProvider).now());
    ref
        .read(keyValueStoreProvider)
        .setString(_key, jsonEncode(anchor.toJson()));
    state = anchor;
  }

  /// Go back to not knowing. Preferable to leaving a figure the user no longer
  /// stands behind.
  void forget() {
    ref.read(keyValueStoreProvider).setString(_key, '');
    state = null;
  }
}

final balanceAnchorProvider =
    NotifierProvider<BalanceAnchorController, BalanceAnchor?>(
        BalanceAnchorController.new);

/// The truthful money picture: real balance, what is already promised, and
/// what is genuinely free between now and the next payday.
final cashPositionProvider = Provider<CashPosition>((ref) {
  final budget = ref.watch(currentBudgetProvider);
  return const CashPositionCalculator().build(
    anchor: ref.watch(balanceAnchorProvider),
    transactions: ref.watch(transactionsProvider).valueOrNull ?? const [],
    rules: ref.watch(recurringProvider),
    now: ref.watch(clockProvider).now(),
    reserve: budget.reserve,
    currency: budget.income.currency,
  );
});

/// What the whole app should quote as today's allowance.
///
/// Once the user has said what they have, every screen must use the figure
/// derived from real money: a Today headline that disagrees with the Money
/// room is worse than either number on its own.
final safeToSpendProvider = Provider<Money>((ref) {
  final cash = ref.watch(cashPositionProvider);
  if (cash.anchored) return cash.perDay;
  return ref.watch(currentBudgetProvider).safeToSpendToday;
});

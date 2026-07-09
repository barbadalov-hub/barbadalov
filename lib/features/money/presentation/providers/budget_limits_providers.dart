import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/i18n/locale_controller.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/features/notifications/domain/entities/app_notification.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_prefs.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Per-category monthly spending limits (minor units), keyed by category id.
class CategoryLimitsController extends Notifier<Map<String, int>> {
  static const _key = 'money.categoryLimits';

  @override
  Map<String, int> build() {
    final raw = ref.watch(keyValueStoreProvider).getString(_key);
    if (raw == null) return const {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {for (final e in map.entries) e.key: (e.value as num).toInt()};
    } catch (_) {
      return const {};
    }
  }

  /// Set (or clear, when [minorUnits] <= 0) a category's monthly limit.
  void setLimit(String categoryId, int minorUnits) {
    final next = {...state};
    if (minorUnits <= 0) {
      next.remove(categoryId);
    } else {
      next[categoryId] = minorUnits;
    }
    ref.read(keyValueStoreProvider).setString(_key, jsonEncode(next));
    state = next;
  }
}

final categoryLimitsProvider =
    NotifierProvider<CategoryLimitsController, Map<String, int>>(
        CategoryLimitsController.new);

/// A category's limit vs. this month's spend.
class CategoryLimitStatus {
  final Category category;
  final Money spent;
  final Money limit;
  const CategoryLimitStatus({
    required this.category,
    required this.spent,
    required this.limit,
  });

  double get ratio =>
      limit.minorUnits == 0 ? 0 : spent.minorUnits / limit.minorUnits;
  bool get over => spent.minorUnits > limit.minorUnits;
}

/// Live status for every category that has a limit set, worst-first.
final categoryLimitStatusProvider =
    Provider<List<CategoryLimitStatus>>((ref) {
  final limits = ref.watch(categoryLimitsProvider);
  final spendByCat = {
    for (final (c, m) in ref.watch(categorySpendingProvider)) c.id: m,
  };
  final out = [
    for (final e in limits.entries)
      CategoryLimitStatus(
        category: DefaultCategories.byId(e.key),
        spent: spendByCat[e.key] ?? const Money.zero(),
        limit: Money(e.value),
      ),
  ]..sort((a, b) => b.ratio.compareTo(a.ratio));
  return out;
});

/// Raises a notification the first time (per month) a category crosses its
/// limit. Kept alive by [HomeShell]; adding to the notification store also fires
/// the phone push and bumps the badge.
final budgetAlertServiceProvider = Provider<void>((ref) {
  void check() => Future.microtask(() {
        try {
          _checkLimits(ref);
        } catch (_) {}
      });

  check();
  ref.listen(categoryLimitStatusProvider, (_, __) => check());
});

const _alertedKey = 'money.limitAlerted';

void _checkLimits(Ref ref) {
  if (!ref.read(notificationPrefsProvider).enabled('budget')) return;
  final now = ref.read(clockProvider).now();
  final monthKey = '${now.year}-${now.month}';
  final store = ref.read(keyValueStoreProvider);
  final alerted = _loadSet(store);
  final repo = ref.read(notificationRepositoryProvider);
  final lang = ref.read(localeProvider)?.languageCode ?? 'en';
  final t = AppLocalizations(lang);

  var changed = false;
  for (final s in ref.read(categoryLimitStatusProvider)) {
    if (!s.over) continue;
    final key = 'limit:$monthKey:${s.category.id}';
    if (alerted.contains(key)) continue;
    repo.add(AppNotification(
      id: key,
      tier: NotificationTier.critical,
      titleKey: 'limit.title',
      bodyKey: 'limit.body',
      params: {
        'cat': t.tr('cat.${s.category.id}'),
        'spent': s.spent.format(),
        'limit': s.limit.format(),
      },
      createdAt: now,
    ));
    alerted.add(key);
    changed = true;
  }
  if (changed) {
    // Keep only the current month's keys so the set stays small.
    final pruned = alerted.where((k) => k.contains(':$monthKey:')).toList();
    store.setString(_alertedKey, jsonEncode(pruned));
  }
}

Set<String> _loadSet(KeyValueStore store) {
  final raw = store.getString(_alertedKey);
  if (raw == null) return <String>{};
  try {
    return {for (final e in jsonDecode(raw) as List) e as String};
  } catch (_) {
    return <String>{};
  }
}

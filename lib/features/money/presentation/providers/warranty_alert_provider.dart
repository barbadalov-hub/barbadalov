import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/money/domain/entities/purchase.dart';
import 'package:lifeos/features/money/presentation/providers/purchase_providers.dart';
import 'package:lifeos/features/notifications/domain/entities/app_notification.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_prefs.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Speaks up while a warranty can still be used.
///
/// A shelf you have to remember to check is a shelf that gets checked after the
/// cover has run out. The whole value is in being told *before* — the last
/// month is long enough to get to the shop and short enough that forgetting
/// costs the claim outright.
///
/// Kept alive by [HomeShell] (`ref.watch`), like the pantry and budget alerts.
final warrantyAlertServiceProvider = Provider<void>((ref) {
  void check(List<Purchase> purchases) {
    Future.microtask(() {
      try {
        _checkWarranties(ref, purchases);
      } catch (_) {
        // A background alert must never take the UI down with it.
      }
    });
  }

  check(ref.read(purchasesProvider));
  ref.listen<List<Purchase>>(purchasesProvider, (_, next) => check(next));
});

const _alertedKey = 'warranty.alerted';

void _checkWarranties(Ref ref, List<Purchase> purchases) {
  if (!ref.read(notificationPrefsProvider).enabled('expiry')) return;
  final now = ref.read(clockProvider).now();
  final store = ref.read(keyValueStoreProvider);
  final alerted = _loadAlerted(store);
  final repo = ref.read(notificationRepositoryProvider);

  var changed = false;
  for (final p in purchases) {
    final state = p.state(now);
    // Only the last month is worth interrupting anyone for. Cover with a year
    // to run is not news, and cover that has already lapsed is not actionable
    // — telling someone they missed it is just a reminder that they lost.
    if (state != CoverState.endingSoon) continue;

    final key = 'warranty:${p.id}';
    if (alerted.contains(key)) continue;

    repo.add(AppNotification(
      id: key,
      tier: NotificationTier.important,
      titleKey: p.kind == CoverKind.warranty
          ? 'warranty.alertTitle'
          : 'warranty.alertExpiryTitle',
      bodyKey: p.hasReceipt
          ? 'warranty.alertBodyWithReceipt'
          : 'warranty.alertBody',
      params: {
        'name': p.title,
        'n': p.daysLeft(now) ?? 0,
      },
      createdAt: now,
    ));
    alerted.add(key);
    changed = true;
  }

  if (changed) {
    // Drop keys for purchases that no longer exist, so a re-bought item can
    // alert again and the set cannot grow forever.
    final live = purchases.map((p) => 'warranty:${p.id}').toSet();
    store.setString(
        _alertedKey, jsonEncode(alerted.where(live.contains).toList()));
  }
}

Set<String> _loadAlerted(KeyValueStore store) {
  final raw = store.getString(_alertedKey);
  if (raw == null) return <String>{};
  try {
    return {for (final e in jsonDecode(raw) as List) e as String};
  } catch (_) {
    return <String>{};
  }
}

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/i18n/locale_controller.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/food/data/meal_catalog.dart';
import 'package:lifeos/features/food/domain/cook_from_pantry.dart';
import 'package:lifeos/features/food/domain/entities/food_item.dart';
import 'package:lifeos/features/food/presentation/providers/food_providers.dart';
import 'package:lifeos/features/notifications/domain/entities/app_notification.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_prefs.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Watches the pantry and raises a notification the first time an item enters
/// the "expiring soon" window and again when it actually expires. Adding to the
/// notification store also fires the phone OS notification (via the store's
/// onAdded hook) and bumps the desktop unread badge — one path, all surfaces.
///
/// Kept alive by [HomeShell] (`ref.watch`). Dedup keys are persisted so a
/// restart doesn't re-alert for the same item/state.
final expiryAlertServiceProvider = Provider<void>((ref) {
  void check(List<FoodItem> items) {
    Future.microtask(() {
      try {
        _checkExpiry(ref, items);
      } catch (_) {
        // Never let a background alert crash the UI.
      }
    });
  }

  // Initial sweep once data has hydrated, then on every pantry change.
  check(ref.read(expiringSoonProvider));
  ref.listen<List<FoodItem>>(expiringSoonProvider, (_, items) => check(items));
});

const _alertedKey = 'food.expiryAlerted';

void _checkExpiry(Ref ref, List<FoodItem> items) {
  if (!ref.read(notificationPrefsProvider).enabled('expiry')) return;
  final now = ref.read(clockProvider).now();
  final store = ref.read(keyValueStoreProvider);
  final alerted = _loadAlerted(store);
  final repo = ref.read(notificationRepositoryProvider);

  final available = ref.read(pantryProductIdsProvider);
  final lang = ref.read(localeProvider)?.languageCode ?? 'en';
  final t = AppLocalizations(lang);

  var changed = false;
  for (final item in items) {
    final expired = item.isExpired(now);
    final key = 'expiry:${item.id}:${expired ? 'x' : 's'}';
    if (alerted.contains(key)) continue;

    final days = item.daysUntilExpiry(now) ?? 0;

    // For a still-good item, suggest a dish that uses it up before it spoils.
    String? bodyKey;
    final params = <String, Object>{
      'emoji': item.emoji,
      'name': item.name,
      'n': days,
    };
    if (!expired && item.productId != null) {
      final dish = const CookFromPantry().bestUsing(
        productId: item.productId!,
        available: available,
        meals: MealCatalog.all,
      );
      if (dish != null) {
        bodyKey = 'food.expiry.soonCook';
        params['dish'] = t.tr(dish.meal.nameKey);
      }
    }
    bodyKey ??= expired ? 'food.expiry.expired' : 'food.expiry.soon';

    repo.add(AppNotification(
      id: key,
      tier: expired ? NotificationTier.critical : NotificationTier.important,
      titleKey: 'food.expiry.title',
      bodyKey: bodyKey,
      params: params,
      createdAt: now,
    ));
    alerted.add(key);
    changed = true;
  }

  if (changed) {
    // Keep only keys for items still in the danger window, so a re-bought item
    // can alert again and the set never grows unbounded.
    final liveIds = items.map((i) => i.id).toSet();
    final pruned = alerted
        .where((k) => liveIds.contains(k.split(':').elementAtOrNull(1)))
        .toList();
    store.setString(_alertedKey, jsonEncode(pruned));
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/food/presentation/providers/expiry_alert_provider.dart';
import 'package:lifeos/features/food/presentation/providers/food_providers.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

void main() {
  test('expiring pantry items raise notifications, once each (deduped)',
      () async {
    final store = InMemoryKeyValueStore();
    final container = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    // The default pantry seeds milk (2d) and bread (1d) — both "expiring soon".
    await container.read(pantryProvider.future);
    final soon = container.read(expiringSoonProvider);
    expect(soon, isNotEmpty);

    final repo = container.read(notificationRepositoryProvider);
    // Keep the watcher alive and let its microtask sweep run.
    container.read(expiryAlertServiceProvider);
    await Future<void>.delayed(Duration.zero);

    final first = repo.all().length;
    expect(first, greaterThan(0));
    expect(repo.all().every((n) => n.titleKey == 'food.expiry.title'), isTrue);
    // Dedup keys were persisted.
    expect(store.getString('food.expiryAlerted'), isNotNull);

    // Simulate a restart: a fresh container over the SAME store must not
    // re-alert for items already recorded in the persisted dedup set.
    final restart = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(restart.dispose);
    await restart.read(pantryProvider.future);
    final restartRepo = restart.read(notificationRepositoryProvider);
    restart.read(expiryAlertServiceProvider);
    await Future<void>.delayed(Duration.zero);
    expect(restartRepo.all(), isEmpty);
  });
}

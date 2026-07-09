import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/backup/presentation/providers/local_backup_provider.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

void main() {
  ProviderContainer containerWith(InMemoryKeyValueStore store) =>
      ProviderContainer(
        overrides: [keyValueStoreProvider.overrideWithValue(store)],
      );

  test('defaults to never backed up', () {
    final c = containerWith(InMemoryKeyValueStore({}));
    addTearDown(c.dispose);
    expect(c.read(backupStatusProvider), isNull);
  });

  test('markExported records the time, reactively and persistently', () {
    final store = InMemoryKeyValueStore({});
    final c = containerWith(store);
    addTearDown(c.dispose);

    c.read(backupStatusProvider.notifier).markExported();
    expect(c.read(backupStatusProvider), isNotNull);
    expect(store.getString('backup.lastExport'), isNotNull);

    // Restored from the same store.
    final c2 = containerWith(store);
    addTearDown(c2.dispose);
    expect(c2.read(backupStatusProvider), isNotNull);
  });

  test('a stored timestamp parses back to a DateTime', () {
    final store = InMemoryKeyValueStore(
        {'backup.lastExport': DateTime(2024, 5, 1).toIso8601String()});
    final c = containerWith(store);
    addTearDown(c.dispose);
    expect(c.read(backupStatusProvider), DateTime(2024, 5, 1));
  });
}

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/backup/presentation/providers/local_backup_provider.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

void main() {
  ProviderContainer withStore(InMemoryKeyValueStore store) {
    final c = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('export omits the cloud session keys', () {
    final store = InMemoryKeyValueStore({
      'money.transactions': '[]',
      'cloud.uid': 'secret',
      'cloud.refreshToken': 'secret2',
    });
    final c = withStore(store);

    final json = c.read(localBackupProvider).exportJson();
    final map = jsonDecode(json) as Map<String, dynamic>;

    expect(map.containsKey('money.transactions'), isTrue);
    expect(map.keys.any((k) => k.startsWith('cloud.')), isFalse);
    expect(c.read(localBackupProvider).entryCount, 1);
  });

  test('import merges data, skips cloud keys, and reloads repositories', () {
    final store = InMemoryKeyValueStore({'cloud.uid': 'keep-me'});
    final c = withStore(store);

    // Seed data is present before import.
    expect(c.read(moneyLocalDataSourceProvider).all(), isNotEmpty);

    const backup = '''
    {
      "money.transactions": "[]",
      "cloud.uid": "should-not-overwrite"
    }''';
    final n = c.read(localBackupProvider).importJson(backup);

    // Only the non-cloud entry was applied…
    expect(n, 1);
    expect(store.getString('cloud.uid'), 'keep-me');
    // …and the money repo rebuilt from the imported (empty) list.
    expect(c.read(moneyLocalDataSourceProvider).all(), isEmpty);
  });

  test('import rejects invalid JSON with a FormatException', () {
    final c = withStore(InMemoryKeyValueStore());
    expect(() => c.read(localBackupProvider).importJson('not json'),
        throwsFormatException);
    expect(() => c.read(localBackupProvider).importJson('[1,2,3]'),
        throwsFormatException);
    expect(() => c.read(localBackupProvider).importJson('{"cloud.uid":"x"}'),
        throwsFormatException); // nothing restorable
  });
}

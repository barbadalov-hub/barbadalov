import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/theme_controller.dart';

void main() {
  ProviderContainer containerWith(InMemoryKeyValueStore store) =>
      ProviderContainer(
        overrides: [keyValueStoreProvider.overrideWithValue(store)],
      );

  test('accentById falls back to the default for unknown ids', () {
    expect(accentById('nope').id, kAccents.first.id);
    expect(accentById('aurora').id, 'aurora');
  });

  test('defaults to the first accent and system mode', () {
    final c = containerWith(InMemoryKeyValueStore({}));
    addTearDown(c.dispose);
    final s = c.read(themeSettingsProvider);
    expect(s.accentId, kAccents.first.id);
    expect(s.mode, ThemeMode.system);
  });

  test('setting accent and mode updates state and persists', () {
    final store = InMemoryKeyValueStore({});
    final c = containerWith(store);
    addTearDown(c.dispose);

    c.read(themeSettingsProvider.notifier)
      ..setAccent('ocean')
      ..setMode(ThemeMode.dark);

    final s = c.read(themeSettingsProvider);
    expect(s.accentId, 'ocean');
    expect(s.mode, ThemeMode.dark);
    expect(store.getString('theme.accent'), 'ocean');
    expect(store.getString('theme.mode'), 'dark');

    // A fresh container over the same store restores the choice.
    final c2 = containerWith(store);
    addTearDown(c2.dispose);
    final restored = c2.read(themeSettingsProvider);
    expect(restored.accentId, 'ocean');
    expect(restored.mode, ThemeMode.dark);
  });
}

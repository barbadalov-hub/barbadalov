import 'package:lifeos/core/services/key_value_store.dart';
import 'package:web/web.dart' as web;

/// Web persistence backed by the browser's synchronous `localStorage`. Pure
/// `package:web` (js_interop) — no Flutter plugin.
Future<KeyValueStore> createPersistentStore() async => _LocalStorageStore();

class _LocalStorageStore implements KeyValueStore {
  final web.Storage _storage = web.window.localStorage;

  @override
  String? getString(String key) => _storage.getItem(key);

  @override
  void setString(String key, String value) => _storage.setItem(key, value);

  @override
  Map<String, String> snapshot() {
    final out = <String, String>{};
    for (var i = 0; i < _storage.length; i++) {
      final key = _storage.key(i);
      if (key == null) continue;
      final value = _storage.getItem(key);
      if (value != null) out[key] = value;
    }
    return out;
  }

  @override
  void putAll(Map<String, String> entries) {
    for (final e in entries.entries) {
      _storage.setItem(e.key, e.value);
    }
  }
}

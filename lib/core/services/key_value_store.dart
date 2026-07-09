/// Minimal synchronous key-value persistence used by repositories to survive
/// app restarts. Kept sync so the in-memory repositories stay simple — the
/// concrete implementations cache values in memory after an async init.
abstract class KeyValueStore {
  String? getString(String key);
  void setString(String key, String value);

  /// A full copy of every stored key/value — used to back the local state up
  /// to the cloud.
  Map<String, String> snapshot();

  /// Bulk-write (merge) many entries at once — used to restore a cloud backup.
  void putAll(Map<String, String> entries);
}

/// Default binding: ephemeral, no platform channel. Used in tests and as a safe
/// fallback before `main()` overrides it with the real store.
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _values;
  InMemoryKeyValueStore([Map<String, String>? seed]) : _values = {...?seed};

  @override
  String? getString(String key) => _values[key];

  @override
  void setString(String key, String value) => _values[key] = value;

  @override
  Map<String, String> snapshot() => Map<String, String>.from(_values);

  @override
  void putAll(Map<String, String> entries) => _values.addAll(entries);
}

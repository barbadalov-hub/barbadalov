import 'dart:convert';

import 'package:lifeos/core/services/key_value_store.dart';

/// Serialises lists and single objects to/from JSON in a [KeyValueStore].
/// Repositories use this to hydrate on construction and persist on every change.
class JsonCollectionStore {
  final KeyValueStore _store;
  const JsonCollectionStore(this._store);

  List<T> loadList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    required List<T> fallback,
  }) {
    final raw = _store.getString(key);
    if (raw == null) return fallback;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return fallback; // corrupt data → fall back to defaults, never crash.
    }
  }

  void saveList<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) {
    _store.setString(key, jsonEncode(items.map(toJson).toList()));
  }

  T loadObject<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    required T fallback,
  }) {
    final raw = _store.getString(key);
    if (raw == null) return fallback;
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return fallback;
    }
  }

  void saveObject<T>(
    String key,
    T item,
    Map<String, dynamic> Function(T) toJson,
  ) {
    _store.setString(key, jsonEncode(toJson(item)));
  }
}

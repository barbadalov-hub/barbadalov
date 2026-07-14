import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:lifeos/core/services/key_value_store.dart';

/// Desktop/mobile persistence: a single JSON file under the user's app-data
/// directory. Pure `dart:io` — no plugin, so Windows builds need no symlink
/// support. All keys are loaded into memory on init so reads stay synchronous.
Future<KeyValueStore> createPersistentStore() async {
  final file = File('${_baseDir()}${Platform.pathSeparator}lifeos_store.json');
  final map = <String, String>{};
  try {
    if (await file.exists()) {
      final decoded =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      decoded.forEach((k, v) => map[k] = v as String);
    }
  } catch (_) {
    // Corrupt or unreadable → start clean rather than crash on launch.
  }
  return _FileKeyValueStore(file, map);
}

String _baseDir() {
  final env = Platform.environment;
  final base = env['APPDATA'] ??
      env['LOCALAPPDATA'] ??
      env['HOME'] ??
      Directory.systemTemp.path;
  return '$base${Platform.pathSeparator}Lumo';
}

class _FileKeyValueStore implements KeyValueStore {
  final File _file;
  final Map<String, String> _map;
  _FileKeyValueStore(this._file, this._map);

  @override
  String? getString(String key) => _map[key];

  @override
  void setString(String key, String value) {
    _map[key] = value;
    unawaited(_write());
  }

  @override
  Map<String, String> snapshot() => Map<String, String>.from(_map);

  @override
  void putAll(Map<String, String> entries) {
    _map.addAll(entries);
    unawaited(_write());
  }

  Future<void> _write() async {
    try {
      await _file.parent.create(recursive: true);
      await _file.writeAsString(jsonEncode(_map));
    } catch (_) {
      // Best-effort persistence; never let a write failure break the UI.
    }
  }
}

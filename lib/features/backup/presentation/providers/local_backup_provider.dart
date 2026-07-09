import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Account-free, offline backup: serialise the whole local store to JSON (the
/// user can copy it anywhere or download a file) and restore it by pasting the
/// JSON back. The device session keys (`cloud.*`) are excluded so importing a
/// backup on another device never hijacks its identity.
class LocalBackupService {
  final Ref _ref;
  const LocalBackupService(this._ref);

  /// Pretty-printed JSON of every stored value except the cloud session.
  String exportJson() {
    final snap = _ref.read(keyValueStoreProvider).snapshot()
      ..removeWhere((k, _) => k.startsWith('cloud.'));
    return const JsonEncoder.withIndent('  ').convert(snap);
  }

  /// Number of key/value entries currently in a backup (for the UI count).
  int get entryCount {
    final snap = _ref.read(keyValueStoreProvider).snapshot()
      ..removeWhere((k, _) => k.startsWith('cloud.'));
    return snap.length;
  }

  /// Merge a backup JSON string into the local store and rebuild every repo.
  /// Returns the number of entries applied. Throws [FormatException] on bad
  /// input so the UI can show a clear error.
  int importJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Backup must be a JSON object');
    }
    final entries = decoded.map((k, v) => MapEntry('$k', '$v'))
      ..removeWhere((k, _) => k.startsWith('cloud.'));
    if (entries.isEmpty) {
      throw const FormatException('Backup contains no restorable data');
    }
    _ref.read(keyValueStoreProvider).putAll(entries);
    // Rebuild every repository that reads the store (money/food/health/…).
    _ref.read(dataEpochProvider.notifier).state++;
    return entries.length;
  }
}

final localBackupProvider =
    Provider<LocalBackupService>((ref) => LocalBackupService(ref));

/// When the user last exported a backup (null = never). Reactive so the Today
/// backup nudge disappears the moment a backup is made.
class BackupStatusController extends Notifier<DateTime?> {
  static const _key = 'backup.lastExport';

  @override
  DateTime? build() {
    final raw = ref.watch(keyValueStoreProvider).getString(_key);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  void markExported() {
    final now = ref.read(clockProvider).now();
    ref.read(keyValueStoreProvider).setString(_key, now.toIso8601String());
    state = now;
  }
}

final backupStatusProvider =
    NotifierProvider<BackupStatusController, DateTime?>(
        BackupStatusController.new);

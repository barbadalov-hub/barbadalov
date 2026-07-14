import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/config/firebase_config.dart';
import 'package:lifeos/features/cloud/application/cloud_sync_handler.dart';
import 'package:lifeos/features/cloud/data/firebase_rest_client.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Live cloud-sync counters for the status tile.
class CloudSyncStatus {
  final bool configured;
  final int synced;
  final int failed;
  const CloudSyncStatus({
    required this.configured,
    this.synced = 0,
    this.failed = 0,
  });
}

/// The signed-in account's email, or null when the device is still anonymous.
/// Persisted so the "Account" tile shows the right state on launch.
final accountEmailProvider = StateProvider<String?>(
  (ref) => ref.watch(keyValueStoreProvider).getString('cloud.email'),
);

/// Whether a real account is required before the app can be used. True only
/// when a cloud project is configured (so a database exists to register into);
/// off by default so the app still runs fully offline. Overridable in tests.
final authRequiredProvider =
    Provider<bool>((ref) => FirebaseConfig.isConfigured);

/// The device's cloud session survives restarts: uid + refresh token live in
/// the local store, so one device = one identity forever. Linking an email
/// keeps the same uid and lets that history follow you to other devices.
final firebaseRestClientProvider = Provider<FirebaseRestClient>((ref) {
  final store = ref.watch(keyValueStoreProvider);
  return FirebaseRestClient(
    savedUid: store.getString('cloud.uid'),
    savedRefreshToken: store.getString('cloud.refreshToken'),
    savedEmail: store.getString('cloud.email'),
    onSession: (uid, refreshToken) {
      store.setString('cloud.uid', uid);
      store.setString('cloud.refreshToken', refreshToken);
    },
    onEmail: (email) {
      store.setString('cloud.email', email ?? '');
      ref.read(accountEmailProvider.notifier).state =
          (email?.isEmpty ?? true) ? null : email;
    },
  );
});

final cloudSyncStatusProvider = StateProvider<CloudSyncStatus>(
  (ref) => CloudSyncStatus(configured: FirebaseConfig.isConfigured),
);

/// Full-state cloud backup & restore — the "your data follows you" feature.
/// Backs up the whole local key-value store (minus the device session keys) to
/// `backups/{uid}` and can restore it on any device signed into the account.
/// State = the last-backup ISO timestamp, or null.
class CloudBackupController extends Notifier<String?> {
  @override
  String? build() {
    final ts = ref.watch(keyValueStoreProvider).getString('cloud.lastBackup');
    return (ts == null || ts.isEmpty) ? null : ts;
  }

  Future<bool> backup() async {
    final store = ref.read(keyValueStoreProvider);
    final snap = store.snapshot()
      ..removeWhere((k, _) => k.startsWith('cloud.')); // never back up the session
    final ok = await ref
        .read(firebaseRestClientProvider)
        .uploadBackup(jsonEncode(snap));
    if (ok) {
      final ts = DateTime.now().toIso8601String();
      store.setString('cloud.lastBackup', ts);
      state = ts;
    }
    return ok;
  }

  Future<bool> restore() async {
    final raw = await ref.read(firebaseRestClientProvider).downloadBackup();
    if (raw == null) return false;
    try {
      final decoded = (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, '$v'))
        ..removeWhere((k, _) => k.startsWith('cloud.'));
      ref.read(keyValueStoreProvider).putAll(decoded);
      // Rebuild every repository that reads the store.
      ref.read(dataEpochProvider.notifier).state++;
      return true;
    } catch (_) {
      return false;
    }
  }
}

final cloudBackupProvider =
    NotifierProvider<CloudBackupController, String?>(CloudBackupController.new);

/// The engine handler; registered in `coreEngineProvider`.
final cloudSyncHandlerProvider = Provider<CloudSyncHandler>((ref) {
  return CloudSyncHandler(
    ref.watch(firebaseRestClientProvider),
    onProgress: (synced, failed) {
      ref.read(cloudSyncStatusProvider.notifier).state = CloudSyncStatus(
        configured: FirebaseConfig.isConfigured,
        synced: synced,
        failed: failed,
      );
    },
  );
});

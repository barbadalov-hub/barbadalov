import 'package:lifeos/core/config/firebase_config.dart';
import 'package:lifeos/core/events/event_handler.dart';
import 'package:lifeos/core/events/life_event.dart';
import 'package:lifeos/features/cloud/data/firebase_rest_client.dart';

/// Mirrors every [LifeEvent] envelope to the Firestore `events/{uid}/log`
/// collection — the cloud copy of the append-only life history, exactly as
/// sketched in docs/ARCHITECTURE.md. Registered with the LifeCoreEngine like
/// any other reaction; when Firebase isn't configured it stays dormant and the
/// app remains fully offline.
class CloudSyncHandler implements EventHandler {
  final FirebaseRestClient _client;
  final void Function(int synced, int failed)? onProgress;

  int _synced = 0;
  int _failed = 0;

  CloudSyncHandler(this._client, {this.onProgress});

  int get synced => _synced;
  int get failed => _failed;

  @override
  String get name => 'CloudSync';

  @override
  bool canHandle(LifeEvent event) => FirebaseConfig.isConfigured;

  @override
  Future<void> handle(LifeEvent event) async {
    // Restores the persisted device session (refresh token) or creates one.
    if (!await _client.ensureSignedIn()) {
      _failed++;
      onProgress?.call(_synced, _failed);
      return;
    }
    final ok = await _client.appendEvent(event.toEnvelope());
    ok ? _synced++ : _failed++;
    onProgress?.call(_synced, _failed);
  }
}

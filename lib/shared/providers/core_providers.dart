import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/engine/life_core_engine.dart';
import 'package:lifeos/core/events/event_bus.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/event_log.dart';
import 'package:lifeos/core/services/id_service.dart';
import 'package:lifeos/core/services/json_collection_store.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/core/services/life_score_service.dart';
import 'package:lifeos/features/ai/presentation/providers/ai_providers.dart';
import 'package:lifeos/features/cloud/presentation/providers/cloud_providers.dart';
import 'package:lifeos/features/notifications/application/notification_event_handler.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_providers.dart';

/// Composition root for the Core layer. Every dependency is exposed as a
/// provider so features never construct their own singletons and tests can
/// override any of them.

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final idServiceProvider = Provider<IdService>((ref) => const UuidIdService());

final lifeScoreServiceProvider =
    Provider<LifeScoreService>((ref) => const LifeScoreService());

/// Persistence binding. Defaults to ephemeral in-memory (tests, and a safe
/// fallback); `main()` overrides it with a [SharedPrefsStore] so real data
/// survives restarts.
final keyValueStoreProvider =
    Provider<KeyValueStore>((ref) => InMemoryKeyValueStore());

/// Bumped after a cloud restore so every repository that reads the store
/// rebuilds and picks up the freshly-restored data.
final dataEpochProvider = StateProvider<int>((ref) => 0);

final jsonStoreProvider = Provider<JsonCollectionStore>((ref) {
  ref.watch(dataEpochProvider);
  return JsonCollectionStore(ref.watch(keyValueStoreProvider));
});

final eventBusProvider = Provider<EventBus>((ref) {
  final bus = EventBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final eventLogProvider = Provider<EventLog>((ref) {
  final log = EventLog();
  ref.onDispose(log.dispose);
  return log;
});

/// Builds, wires and **starts** the LifeCoreEngine. Reading this provider once
/// at bootstrap brings the whole event pipeline to life:
///
///   EventBus → LifeCoreEngine → [EventLogHandler, ...] → side effects
final coreEngineProvider = Provider<LifeCoreEngine>((ref) {
  final aiHandler = ref.watch(aiEventHandlerProvider);
  final engine = LifeCoreEngine(
    ref.watch(eventBusProvider),
    handlers: [
      // Universal: append every event to the events/ log.
      EventLogHandler(ref.watch(eventLogProvider)),
      // Phase 6: turn events into tiered notifications.
      NotificationEventHandler(
        ref.watch(notificationRepositoryProvider),
        ref.watch(idServiceProvider),
        ref.watch(clockProvider),
      ),
      // Phase 9: re-run AI analysis on every event.
      aiHandler,
      // Cloud: mirror the event log to Firestore (dormant until configured).
      ref.watch(cloudSyncHandlerProvider),
    ],
  );
  engine.start();
  // Seed AI insights so Today has guidance before the first user event.
  aiHandler.analyzeNow();
  ref.onDispose(engine.dispose);
  return engine;
});

/// Live view of the append-only event log for debug / "activity" surfaces.
final eventLogStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(eventLogProvider).watch();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/health/domain/entities/activity_entry.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:uuid/uuid.dart';

/// The training sessions the user has logged.
class ActivityController extends Notifier<List<ActivityEntry>> {
  static const _key = 'health.activities';
  static const _uuid = Uuid();

  /// Roughly a year of daily training, after which the oldest entries drop.
  /// Long enough for any history the app shows, short enough that the stored
  /// list cannot grow forever.
  static const _maxKept = 500;

  @override
  List<ActivityEntry> build() =>
      ref.watch(jsonStoreProvider).loadList<ActivityEntry>(
            _key,
            ActivityEntry.fromJson,
            fallback: const [],
          );

  ActivityEntry add(ActivityKind kind, int minutes, {DateTime? at}) {
    final entry = ActivityEntry(
      id: _uuid.v4(),
      kind: kind,
      minutes: minutes,
      at: at ?? ref.read(clockProvider).now(),
    );
    final next = [...state, entry];
    if (next.length > _maxKept) next.removeRange(0, next.length - _maxKept);
    _persist(next);
    return entry;
  }

  /// Takes one back. The reason this exists at all: a mis-tap should cost one
  /// tap to undo, not a trip through an edit screen.
  void remove(String id) =>
      _persist(state.where((e) => e.id != id).toList());

  /// Puts a removed entry back exactly as it was, id included, so an undo
  /// restores rather than creates something that merely looks the same.
  void restore(ActivityEntry entry) {
    if (state.any((e) => e.id == entry.id)) return;
    _persist([...state, entry]);
  }

  void _persist(List<ActivityEntry> next) {
    ref
        .read(jsonStoreProvider)
        .saveList<ActivityEntry>(_key, next, (e) => e.toJson());
    state = next;
  }
}

final activitiesProvider =
    NotifierProvider<ActivityController, List<ActivityEntry>>(
        ActivityController.new);

/// Today's sessions, newest first.
final todayActivitiesProvider = Provider<List<ActivityEntry>>((ref) {
  return activitiesOn(
      ref.watch(activitiesProvider), ref.watch(clockProvider).now());
});

/// Minutes trained today — the figure the room shows.
final todayActiveMinutesProvider =
    Provider<int>((ref) => totalMinutes(ref.watch(todayActivitiesProvider)));

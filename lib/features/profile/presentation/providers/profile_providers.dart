import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/profile/domain/checkup_advisor.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';
import 'package:lifeos/features/profile/domain/events/profile_events.dart';
import 'package:lifeos/features/profile/domain/fitness_calculator.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// The saved profile, or null until the user fills it in. Persisted as JSON.
class ProfileController extends Notifier<UserProfile?> {
  static const _key = 'profile.user';

  @override
  UserProfile? build() {
    final store = ref.watch(jsonStoreProvider);
    // loadObject needs a non-null fallback, so probe with a sentinel read.
    final raw = ref.watch(keyValueStoreProvider).getString(_key);
    if (raw == null) return null;
    return store.loadObject(_key, UserProfile.fromJson,
        fallback: const UserProfile(
          name: '',
          sex: Sex.male,
          age: 30,
          heightCm: 175,
          weightKg: 75,
        ));
  }

  void save(UserProfile profile) {
    ref
        .read(jsonStoreProvider)
        .saveObject(_key, profile, (p) => p.toJson());
    state = profile;
    // Iron rule: every change is an event through the Core Engine.
    ref.read(eventBusProvider).publish(ProfileUpdatedEvent(
          id: ref.read(idServiceProvider).newId(),
          userId: 'local',
          occurredAt: ref.read(clockProvider).now(),
          weightKg: profile.weightKg,
          heightCm: profile.heightCm,
          goal: profile.goal.name,
        ));
  }
}

final profileProvider =
    NotifierProvider<ProfileController, UserProfile?>(ProfileController.new);

final fitnessCalculatorProvider =
    Provider<FitnessCalculator>((ref) => const FitnessCalculator());

/// Per-suggestion check-up progress (todo → planned → done), persisted so the
/// advisor becomes a real, trackable health to-do list. Keyed by
/// [CheckupSuggestion.trackKey]; only non-todo entries are stored.
class CheckupTrackerController extends Notifier<Map<String, CheckupStatus>> {
  static const _key = 'checkup.status';

  @override
  Map<String, CheckupStatus> build() {
    final raw = ref.watch(keyValueStoreProvider).getString(_key) ?? '';
    final byName = {for (final s in CheckupStatus.values) s.name: s};
    final out = <String, CheckupStatus>{};
    for (final part in raw.split(',')) {
      final bits = part.split(':');
      if (bits.length != 2) continue;
      final status = byName[bits[1]];
      if (status != null && status != CheckupStatus.todo) {
        out[bits[0]] = status;
      }
    }
    return out;
  }

  CheckupStatus statusOf(String key) => state[key] ?? CheckupStatus.todo;

  /// Advance a suggestion to its next state: todo → planned → done → todo.
  void cycle(String key) {
    final current = statusOf(key);
    final next = CheckupStatus.values[(current.index + 1) % 3];
    final map = {...state};
    if (next == CheckupStatus.todo) {
      map.remove(key);
    } else {
      map[key] = next;
    }
    ref.read(keyValueStoreProvider).setString(
        _key, map.entries.map((e) => '${e.key}:${e.value.name}').join(','));
    state = map;
  }
}

final checkupTrackerProvider =
    NotifierProvider<CheckupTrackerController, Map<String, CheckupStatus>>(
        CheckupTrackerController.new);

/// Live assessment (BMI/BMR/TDEE/targets), or null while no profile is saved.
final assessmentProvider = Provider<FitnessAssessment?>((ref) {
  final profile = ref.watch(profileProvider);
  if (profile == null) return null;
  return ref.watch(fitnessCalculatorProvider).assess(profile);
});

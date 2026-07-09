import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Live assessment (BMI/BMR/TDEE/targets), or null while no profile is saved.
final assessmentProvider = Provider<FitnessAssessment?>((ref) {
  final profile = ref.watch(profileProvider);
  if (profile == null) return null;
  return ref.watch(fitnessCalculatorProvider).assess(profile);
});

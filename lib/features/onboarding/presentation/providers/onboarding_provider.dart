import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Whether the first-run onboarding has been completed (persisted).
class OnboardingController extends Notifier<bool> {
  static const _key = 'onboarding.done';

  @override
  bool build() =>
      ref.watch(keyValueStoreProvider).getString(_key) == 'true';

  void complete() {
    ref.read(keyValueStoreProvider).setString(_key, 'true');
    state = true;
  }
}

final onboardingDoneProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);

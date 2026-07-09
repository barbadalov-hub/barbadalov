import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/security/application/pin_service.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Whether an app-lock PIN is set. Persisted as a salted hash at
/// `security.pinHash` (empty = disabled).
class SecurityController extends Notifier<bool> {
  static const _key = 'security.pinHash';
  static const _service = PinService();

  @override
  bool build() =>
      (ref.watch(keyValueStoreProvider).getString(_key) ?? '').isNotEmpty;

  bool verify(String pin) => _service.verify(
        pin,
        ref.read(keyValueStoreProvider).getString(_key) ?? '',
      );

  void setPin(String pin) {
    ref.read(keyValueStoreProvider).setString(_key, _service.hash(pin));
    state = true;
  }

  void disable() {
    ref.read(keyValueStoreProvider).setString(_key, '');
    state = false;
  }
}

final pinEnabledProvider =
    NotifierProvider<SecurityController, bool>(SecurityController.new);

/// True while the app is locked and awaiting the PIN. Starts locked whenever a
/// PIN is set (checked once at launch).
final appLockedProvider = StateProvider<bool>(
  (ref) => ref.read(pinEnabledProvider),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Whether the user has LifeOS Pro. Persisted via the [KeyValueStore]. Pro
/// unlocks AI features, predictions, deep analytics and integrations (spec §20).
/// Phase-1 "purchase" is a local toggle; wire a real store/IAP here later.
class ProController extends Notifier<bool> {
  static const _key = 'app.pro';

  @override
  bool build() => ref.watch(keyValueStoreProvider).getString(_key) == '1';

  void setPro(bool value) {
    ref.read(keyValueStoreProvider).setString(_key, value ? '1' : '0');
    state = value;
  }
}

final isProProvider = NotifierProvider<ProController, bool>(ProController.new);

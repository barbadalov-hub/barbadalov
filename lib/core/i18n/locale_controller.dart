import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Holds the user-selected locale (`null` = follow the system). Persisted via
/// the [KeyValueStore] so the choice survives restarts.
class LocaleController extends Notifier<Locale?> {
  static const _key = 'app.locale';

  @override
  Locale? build() {
    final code = ref.watch(keyValueStoreProvider).getString(_key);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  void setLocale(Locale? locale) {
    ref.read(keyValueStoreProvider).setString(_key, locale?.languageCode ?? '');
    state = locale;
  }
}

final localeProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);

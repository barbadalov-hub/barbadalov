import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// A named cosmos accent the user can pick. [seed] drives the whole Material
/// colour scheme; [gradient] is the swatch/preview look.
class AccentPalette {
  final String id;
  final String nameKey;
  final Color seed;
  final List<Color> gradient;

  const AccentPalette(this.id, this.nameKey, this.seed, this.gradient);
}

/// The palette catalog. First entry is the default (cosmic violet).
const kAccents = <AccentPalette>[
  AccentPalette('violet', 'theme.violet', Color(0xFF7C6BFF),
      [Color(0xFF7B5CFF), Color(0xFF2A1A5E)]),
  AccentPalette('aurora', 'theme.aurora', Color(0xFF2BD9C0),
      [Color(0xFF11998E), Color(0xFF38EF7D)]),
  AccentPalette('sunset', 'theme.sunset', Color(0xFFFF7A45),
      [Color(0xFFF83600), Color(0xFFFE8C00)]),
  AccentPalette('rose', 'theme.rose', Color(0xFFFF5DA2),
      [Color(0xFFFF6CAB), Color(0xFF7366FF)]),
  AccentPalette('ocean', 'theme.ocean', Color(0xFF3B82F6),
      [Color(0xFF2E3192), Color(0xFF1BFFFF)]),
  AccentPalette('gold', 'theme.gold', Color(0xFFF7B733),
      [Color(0xFFF7971E), Color(0xFFFFD200)]),
];

AccentPalette accentById(String id) =>
    kAccents.firstWhere((a) => a.id == id, orElse: () => kAccents.first);

/// The persisted appearance choice: accent + light/dark/system.
class ThemeSettings {
  final String accentId;
  final ThemeMode mode;
  const ThemeSettings({required this.accentId, required this.mode});

  AccentPalette get accent => accentById(accentId);
}

ThemeMode _modeFrom(String? s) => switch (s) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

class ThemeController extends Notifier<ThemeSettings> {
  static const _accentKey = 'theme.accent';
  static const _modeKey = 'theme.mode';

  @override
  ThemeSettings build() {
    final store = ref.watch(keyValueStoreProvider);
    return ThemeSettings(
      accentId: store.getString(_accentKey) ?? kAccents.first.id,
      mode: _modeFrom(store.getString(_modeKey)),
    );
  }

  void setAccent(String id) {
    ref.read(keyValueStoreProvider).setString(_accentKey, id);
    state = ThemeSettings(accentId: id, mode: state.mode);
  }

  void setMode(ThemeMode mode) {
    ref.read(keyValueStoreProvider).setString(_modeKey, mode.name);
    state = ThemeSettings(accentId: state.accentId, mode: mode);
  }
}

final themeSettingsProvider =
    NotifierProvider<ThemeController, ThemeSettings>(ThemeController.new);

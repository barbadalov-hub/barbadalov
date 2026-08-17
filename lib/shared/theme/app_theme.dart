import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Central Material 3 theme. UI code pulls colours and text styles from here so
/// the look stays consistent and re-skinnable in one place.
class AppTheme {
  const AppTheme._();

  static const _seed = Color(0xFF7C6BFF); // cosmic violet (default accent)

  // --- Paper skin ---------------------------------------------------------
  /// The warm page the light theme is printed on.
  static const paperBg = Color(0xFFF4F1E9);

  /// Raised surfaces (cards) sit *above* the page, toward white.
  static const paperRaised = Color(0xFFFBF9F4);

  /// Recessed tiles (quiet chips, wells) sit just below the page.
  static const paperTile = Color(0xFFEBE6DA);

  static const paperInk = Color(0xFF1E1C19);
  static const paperMuted = Color(0xFF7C776C);
  static const paperBorder = Color(0xFFDFD9CA);

  static ThemeData light([Color seed = _seed]) => _build(Brightness.light, seed);
  static ThemeData dark([Color seed = _seed]) => _build(Brightness.dark, seed);

  static ThemeData _build(Brightness brightness, Color seed) {
    var scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    if (brightness == Brightness.dark) {
      // Deep-space dark: near-black void with a nebula tint on surfaces. The
      // primary is a brightened tint of the chosen accent so it pops on black.
      scheme = scheme.copyWith(
        surface: const Color(0xFF05070D),
        surfaceContainerHighest: const Color(0xFF1B2138),
        surfaceContainerHigh: const Color(0xFF141A2C),
        primary: Color.lerp(seed, Colors.white, 0.35),
      );
    } else {
      // Paper: warm cream page, ink text, and a deepened accent so it holds
      // contrast against the light ground. Surfaces step *up* toward white
      // (raised cards) rather than down toward black, which is the opposite of
      // the dark scheme — getting this backwards is what makes light themes
      // look muddy.
      scheme = scheme.copyWith(
        surface: paperBg,
        surfaceContainerLowest: paperRaised,
        surfaceContainerLow: paperRaised,
        surfaceContainerHigh: paperRaised,
        surfaceContainerHighest: paperTile,
        onSurface: paperInk,
        onSurfaceVariant: paperMuted,
        outline: paperMuted,
        outlineVariant: paperBorder,
        primary: Color.lerp(seed, const Color(0xFF1E1C19), 0.34),
      );
    }
    // Bolder display numbers + tighter headings (Ivy-Wallet-style type scale).
    final textTheme = Typography.material2021(platform: TargetPlatform.android)
        .englishLike
        .apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        )
        .copyWith(
          displaySmall: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            color: scheme.onSurface,
          ),
          headlineSmall: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: scheme.onSurface,
          ),
          titleLarge: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: scheme.onSurface,
          ),
          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: scheme.onSurface,
          ),
        );
    // On the web, CanvasKit ships no system fonts and would fetch Roboto, its
    // Noto fallbacks and color emoji from a CDN — breaking offline. Use the
    // bundled subsets instead: RobotoWeb for text, NotoSans for glyphs Roboto
    // lacks (notably ₴), and the color-emoji subset for emoji. Mobile keeps its
    // native system fonts, so this whole stack is web-only.
    //
    // The family is applied directly to every text style (the base Material
    // typography hard-codes 'Roboto', which ThemeData.fontFamily does not
    // override on a supplied textTheme), and to ThemeData for widgets that read
    // the family off the theme rather than a text style.
    const String? webFontFamily = kIsWeb ? 'RobotoWeb' : null;
    const List<String>? webFontFallback =
        kIsWeb ? ['NotoColorEmoji', 'NotoSans', 'DejaVuSymbols'] : null;
    final resolvedTextTheme = kIsWeb
        ? textTheme.apply(
            fontFamily: webFontFamily,
            fontFamilyFallback: webFontFallback,
          )
        : textTheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: webFontFamily,
      fontFamilyFallback: webFontFallback,
      textTheme: resolvedTextTheme,
      // Modern zoom/fade route transitions on every platform (M3 style)
      // instead of the default platform-specific slides.
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const ZoomPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        // Night: a translucent pane floating over the aurora. Paper: an opaque
        // sheet raised toward white with a hairline edge — translucency on a
        // light ground just looks dirty.
        color: brightness == Brightness.dark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.4)
            : paperRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: brightness == Brightness.dark
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFE3DDCE), width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}

/// Semantic colours for the app's domains, used for text, icons and accents in
/// ~100 places across both skins.
///
/// Each value must stay legible on the paper page *and* on the night one, which
/// only mid-tones can do: too light and it vanishes on cream, too dark and it
/// vanishes on near-black. The old amber (`0xFFF5A623`) scored 1.8 against
/// paper — effectively invisible — and the old green 2.99, just under the bar.
/// Both were tuned for a dark-only app. `theme_contrast_test` now holds the
/// line at 3.0 on both skins, so any future tweak is checked rather than
/// eyeballed.
class LifeColors {
  const LifeColors._();

  static const finance = Color(0xFF24855A);
  static const financeDanger = Color(0xFFE5484D);
  static const health = Color(0xFFE5484D);
  static const mind = Color(0xFF8E5BFF);
  static const goals = Color(0xFFB07408);

  /// Every semantic colour, for the contrast guard to iterate.
  static const all = <String, Color>{
    'finance': finance,
    'financeDanger': financeDanger,
    'health': health,
    'mind': mind,
    'goals': goals,
  };
}

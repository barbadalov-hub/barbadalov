import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Central Material 3 theme. UI code pulls colours and text styles from here so
/// the look stays consistent and re-skinnable in one place.
class AppTheme {
  const AppTheme._();

  static const _seed = Color(0xFF7C6BFF); // cosmic violet (default accent)

  static ThemeData light([Color seed = _seed]) => _build(Brightness.light, seed);
  static ThemeData dark([Color seed = _seed]) => _build(Brightness.dark, seed);

  static ThemeData _build(Brightness brightness, Color seed) {
    var scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    // Deep-space dark: near-black void with a nebula tint on surfaces. The
    // primary is a brightened tint of the chosen accent so it pops on black.
    if (brightness == Brightness.dark) {
      scheme = scheme.copyWith(
        surface: const Color(0xFF05070D),
        surfaceContainerHighest: const Color(0xFF1B2138),
        surfaceContainerHigh: const Color(0xFF141A2C),
        primary: Color.lerp(seed, Colors.white, 0.35),
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
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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

/// Semantic colours for LifeOS domains, resolved against the active scheme.
class LifeColors {
  const LifeColors._();

  static const finance = Color(0xFF2E9E6B);
  static const financeDanger = Color(0xFFE5484D);
  static const health = Color(0xFFE5484D);
  static const mind = Color(0xFF8E5BFF);
  static const goals = Color(0xFFF5A623);
}

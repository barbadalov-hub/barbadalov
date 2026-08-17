import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/rooms/domain/life_room.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/theme/theme_controller.dart';

/// Relative luminance per WCAG 2.1.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

/// WCAG contrast ratio between two opaque colours (1.0 – 21.0).
double _contrast(Color fg, Color bg) {
  final a = _luminance(fg), b = _luminance(bg);
  final light = math.max(a, b), dark = math.min(a, b);
  return (light + 0.05) / (dark + 0.05);
}

/// Both skins must stay readable. This is the guard for the bug that once made
/// the app dark-only: ink was rendered onto a dark canvas and disappeared.
void main() {
  const minBodyContrast = 4.5; // WCAG AA for normal text
  const minMutedContrast = 3.0; // AA-large / secondary text

  for (final accent in kAccents) {
    for (final isDark in [false, true]) {
      final name = '${accent.id} · ${isDark ? 'dark' : 'paper'}';
      final theme =
          isDark ? AppTheme.dark(accent.seed) : AppTheme.light(accent.seed);
      final s = theme.colorScheme;

      test('$name: body text is readable on every surface', () {
        for (final entry in <String, Color>{
          'surface': s.surface,
          'surfaceContainerHighest': s.surfaceContainerHighest,
          'surfaceContainerHigh': s.surfaceContainerHigh,
        }.entries) {
          expect(_contrast(s.onSurface, entry.value),
              greaterThanOrEqualTo(minBodyContrast),
              reason: '$name: onSurface on ${entry.key} is too faint');
        }
      });

      test('$name: muted text and the accent still stand out', () {
        expect(_contrast(s.onSurfaceVariant, s.surface),
            greaterThanOrEqualTo(minMutedContrast),
            reason: '$name: muted text is too faint');
        expect(_contrast(s.primary, s.surface),
            greaterThanOrEqualTo(minMutedContrast),
            reason: '$name: accent is too faint on the page');
      });

      test('$name: the scaffold matches the scheme surface', () {
        expect(theme.scaffoldBackgroundColor, s.surface);
      });
    }
  }

  // The semantic colours are single constants shared by both skins (they are
  // used in ~100 places, so per-skin variants would mean touching every call
  // site). That only works if each one sits in the mid-tone band that reads on
  // cream *and* on near-black — this is the guard for that band.
  group('semantic colours', () {
    final paper = AppTheme.light().colorScheme.surface;
    final night = AppTheme.dark().colorScheme.surface;

    LifeColors.all.forEach((name, colour) {
      test('$name is legible on both skins', () {
        expect(_contrast(colour, paper), greaterThanOrEqualTo(minMutedContrast),
            reason: '$name would fade into the paper page');
        expect(_contrast(colour, night), greaterThanOrEqualTo(minMutedContrast),
            reason: '$name would fade into the night page');
      });
    });
  });

  test('paper surfaces are light and dark surfaces are dark', () {
    expect(_luminance(AppTheme.light().colorScheme.surface),
        greaterThan(0.5),
        reason: 'the paper page must actually be light');
    expect(_luminance(AppTheme.dark().colorScheme.surface), lessThan(0.1),
        reason: 'the night page must actually be dark');
  });

  group('the home cover', () {
    test('every room can carry white type at full bleed', () {
      // The lead cover fills itself with the room's paper colour and prints
      // white on top, in both skins. That is only safe because these four are
      // the ink-strength versions — a new room added with a pastel would look
      // fine in the palette and be unreadable the day it leads.
      for (final room in kLifeRooms) {
        expect(_contrast(Colors.white, room.paper), greaterThanOrEqualTo(4.5),
            reason: '${room.id.name}: white on its cover is unreadable');
      }
    });

    test('the supporting copy on a cover still clears the bar', () {
      // The headline sentence is drawn at 92% alpha over the same ground.
      for (final room in kLifeRooms) {
        final faded = Color.alphaBlend(
            Colors.white.withValues(alpha: 0.92), room.paper);
        expect(_contrast(faded, room.paper), greaterThanOrEqualTo(4.5),
            reason: '${room.id.name}: the cover sentence is too faint');
      }
    });
  });
}

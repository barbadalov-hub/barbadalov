import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/rooms/domain/life_room.dart';
import 'package:lifeos/shared/theme/app_theme.dart';

/// How far apart two colours are in hue, in degrees, ignoring how light or
/// saturated they are.
double _hueGap(Color a, Color b) {
  final ha = HSLColor.fromColor(a).hue;
  final hb = HSLColor.fromColor(b).hue;
  final raw = (ha - hb).abs();
  return math.min(raw, 360 - raw);
}

/// A progress track is the unfilled half of the same object, so it has to be
/// the same colour family. Taking it from the theme instead put a cold blue
/// ring on the warm terracotta Body page — the theme surface carries the
/// *accent's* tint, which has nothing to do with the room being drawn.
void main() {
  test('a muted track keeps the hue of the thing it tracks', () {
    for (final skin in {
      'paper': AppTheme.light().colorScheme,
      'night': AppTheme.dark().colorScheme,
    }.entries) {
      for (final room in kLifeRooms) {
        final ring =
            room.colorFor(skin.key == 'night' ? Brightness.dark : Brightness.light);
        final track = Color.lerp(ring, skin.value.surface, 0.78)!;
        expect(
          _hueGap(track, ring),
          lessThan(40),
          reason: '${room.id.name} on ${skin.key}: the track drifted off-hue',
        );
      }
    }
  });

  test('the old theme-grey track really was off-hue for warm rooms', () {
    // Guards the reasoning, not just the fix: if some future theme change made
    // surfaceContainerHighest neutral, this test would fail and the extra
    // plumbing could be dropped.
    final scheme = AppTheme.dark().colorScheme;
    final body = roomById(RoomId.body).colorFor(Brightness.dark);
    expect(_hueGap(scheme.surfaceContainerHighest, body), greaterThan(40));
  });
}

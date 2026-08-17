import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/rooms/domain/life_room.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

double _contrast(Color fg, Color bg) {
  final a = _luminance(fg), b = _luminance(bg);
  final light = math.max(a, b), dark = math.min(a, b);
  return (light + 0.05) / (dark + 0.05);
}

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

  test('each pillar gradient belongs to its own room and carries white', () {
    // These were unrelated cosmic pairs: "safe to spend" was a blue-violet
    // card in an app whose money room is green, so a card never said which
    // room it came from.
    final pairs = {
      RoomId.money: LifeGradients.money,
      RoomId.body: LifeGradients.health,
      RoomId.mind: LifeGradients.mind,
      RoomId.goals: LifeGradients.goals,
    };

    pairs.forEach((id, gradient) {
      final room = roomById(id).paper;
      expect(gradient.first, room,
          reason: '${id.name}: the gradient starts on a different colour '
              'than the room itself');
      for (final stop in gradient) {
        expect(_hueGap(stop, room), lessThan(20),
            reason: '${id.name}: a gradient stop drifted off-hue');
        expect(_contrast(Colors.white, stop), greaterThanOrEqualTo(4.5),
            reason: '${id.name}: white type on this card is unreadable');
      }
    });
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

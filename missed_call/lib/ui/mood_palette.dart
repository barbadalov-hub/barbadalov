import 'package:flutter/material.dart';

import '../engine/models.dart';

/// The colour set for a [Mood]. Atmosphere-as-a-system: the same interface,
/// re-tinted to carry the emotion of the scene.
@immutable
class MoodPalette {
  const MoodPalette({
    required this.bgTop,
    required this.bgBottom,
    required this.panel,
    required this.text,
    required this.accent,
  });

  final Color bgTop;
  final Color bgBottom;
  final Color panel;
  final Color text;
  final Color accent;

  static MoodPalette of(Mood mood) {
    switch (mood) {
      case Mood.night:
        return const MoodPalette(
          bgTop: Color(0xFF182742),
          bgBottom: Color(0xFF080B14),
          panel: Color(0xFF121826),
          text: Color(0xFFD8DEEA),
          accent: Color(0xFF7FB0E6),
        );
      case Mood.memory:
        return const MoodPalette(
          bgTop: Color(0xFF3F3018),
          bgBottom: Color(0xFF160F06),
          panel: Color(0xFF241A0F),
          text: Color(0xFFF0E2C6),
          accent: Color(0xFFE6B45A),
        );
      case Mood.dread:
        return const MoodPalette(
          bgTop: Color(0xFF0F1614),
          bgBottom: Color(0xFF070A08),
          panel: Color(0xFF141D18),
          text: Color(0xFFB9C6BE),
          accent: Color(0xFF6F9E86),
        );
      case Mood.dawn:
        return const MoodPalette(
          bgTop: Color(0xFF2A2416),
          bgBottom: Color(0xFF140F08),
          panel: Color(0xFF2E2416),
          text: Color(0xFFF4E8D0),
          accent: Color(0xFFF2C060),
        );
    }
  }
}

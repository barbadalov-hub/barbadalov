import 'package:flutter/material.dart';
import 'package:lifeos/features/rooms/domain/life_room.dart';

/// Paints everything inside in a room's colour instead of the app's own accent.
///
/// A screen that belongs to a room — the dietitian, the pantry, the workouts —
/// used to fill its buttons, sliders and progress bars with the app's violet,
/// so a page reached from the red Body room came up violet and looked like it
/// had been borrowed from somewhere else. Overriding the scheme once here beats
/// colouring twenty widgets by hand and forgetting the twenty-first.
///
/// The room's **paper** value is used in both skins: those four are the
/// ink-strength colours chosen to carry white type, and `theme_contrast_test`
/// holds them to it — so `onPrimary` stays white and nothing needs tuning.
class RoomTint extends StatelessWidget {
  final RoomId room;
  final Widget child;

  const RoomTint({required this.room, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = roomById(room).paper;
    // `primary` alone is not enough: tonal icon buttons fill from
    // `secondaryContainer` and progress bars take their track from the theme,
    // so a page tinted only on primary still shone with lavender plus signs.
    final scheme = theme.colorScheme.copyWith(
      primary: accent,
      onPrimary: Colors.white,
      secondaryContainer: Color.lerp(accent, theme.colorScheme.surface, 0.85),
      onSecondaryContainer: accent,
    );

    return Theme(
      data: theme.copyWith(
        colorScheme: scheme,
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: accent,
          linearTrackColor:
              Color.lerp(accent, theme.colorScheme.surface, 0.85),
        ),
      ),
      child: child,
    );
  }
}

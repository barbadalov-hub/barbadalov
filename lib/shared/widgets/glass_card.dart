import 'dart:ui';

import 'package:flutter/material.dart';

/// A frosted-glass surface for the cosmos theme: a translucent panel with a
/// light border and a soft top sheen over the animated backdrop. [blur] > 0
/// adds a real backdrop blur (use sparingly — one hero per screen); the default
/// is a cheap translucent frost safe to use in long lists.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final VoidCallback? onTap;

  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.blur = 0,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(20);

    // Frost only works over the dark canvas. On the paper skin the same recipe
    // is translucent *black*, which is not glass but grey mud — the More hub
    // was a column of dead slate on a warm page. Paper gets what every other
    // surface in this app gets: an opaque sheet raised toward white with a
    // hairline edge. Same reasoning as `AppTheme.cardTheme`.
    Widget surface = DecoratedBox(
      decoration: dark
          ? BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.14),
                  Colors.white.withValues(alpha: 0.06),
                ],
              ),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            )
          : BoxDecoration(
              borderRadius: radius,
              color: scheme.surfaceContainerLowest,
              border: Border.all(color: scheme.outlineVariant, width: 0.5),
            ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      surface = Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: surface),
      );
    }

    Widget card = ClipRRect(borderRadius: radius, child: surface);
    if (blur > 0) {
      card = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: surface,
        ),
      );
    }

    return margin == null ? card : Padding(padding: margin!, child: card);
  }
}

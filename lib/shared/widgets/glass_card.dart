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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? Colors.white : Colors.black;
    final radius = BorderRadius.circular(20);

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base.withValues(alpha: dark ? 0.14 : 0.06),
            base.withValues(alpha: dark ? 0.06 : 0.03),
          ],
        ),
        border: Border.all(color: base.withValues(alpha: 0.16), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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

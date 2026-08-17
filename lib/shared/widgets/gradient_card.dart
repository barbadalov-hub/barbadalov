import 'package:flutter/material.dart';

/// Hero surface: linear gradient + a soft glow shadow in the gradient's own
/// colour — the signature look of the popular Flutter fitness/finance UI
/// templates, reimplemented cleanly. Use for each module's headline card.
class GradientCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GradientCard({
    required this.colors,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Module gradient palettes (dark-theme friendly).
class LifeGradients {
  const LifeGradients._();

  // Each pillar's gradient is its room's ink colour, deepened by about a
  // quarter. They used to be unrelated cosmic pairs left from the old
  // branding — "safe to spend" was a blue-violet card while the money room is
  // green — so a card never told you which room it came from. The lighter stop
  // is the exact room accent, which theme_contrast_test already holds to
  // carrying white type.
  static const money = [Color(0xFF0F6E56), Color(0xFF0B5441)];
  static const finance = money;
  static const health = [Color(0xFF993C1D), Color(0xFF742E16)];
  static const diet = health;
  static const goals = [Color(0xFF854F0B), Color(0xFF653C08)];
  static const mind = [Color(0xFF185FA5), Color(0xFF12487D)];
}

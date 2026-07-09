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

  static const money = [Color(0xFF3B5BFE), Color(0xFF7B3BFE)];
  static const finance = [Color(0xFF11998E), Color(0xFF38EF7D)];
  static const health = [Color(0xFFF5576C), Color(0xFFF093FB)];
  static const diet = [Color(0xFF0BA360), Color(0xFF3CBA92)];
  static const goals = [Color(0xFFF7971E), Color(0xFFFFD200)];
  static const mind = [Color(0xFF7F53AC), Color(0xFF647DEE)];
}

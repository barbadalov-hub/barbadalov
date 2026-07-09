import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Number that rolls to its new value (money amounts, scores). The classic
/// "counting up" micro-interaction from finance-app templates.
class AnimatedCounter extends StatelessWidget {
  final double value;
  final String Function(double value) format;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounter({
    required this.value,
    required this.format,
    this.style,
    this.duration = const Duration(milliseconds: 700),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(format(v), style: style),
    );
  }
}

/// Staggered entrance: fade + slide-up, delayed by [index] — the one-controller
/// cascade the popular UI templates use for list screens.
class FadeSlideIn extends StatefulWidget {
  final int index;
  final Widget child;

  const FadeSlideIn({required this.index, required this.child, super.key});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 60 * widget.index.clamp(0, 10)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Progress ring with a gradient sweep stroke and rounded caps — replaces the
/// stock [CircularProgressIndicator] look everywhere scores are shown.
class GradientRing extends StatelessWidget {
  final double progress; // 0..1
  final double size;
  final double strokeWidth;
  final List<Color> colors;
  final Widget? center;

  const GradientRing({
    required this.progress,
    required this.colors,
    this.size = 72,
    this.strokeWidth = 8,
    this.center,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0).toDouble()),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => CustomPaint(
          painter: _RingPainter(
            progress: value,
            strokeWidth: strokeWidth,
            colors: colors,
            trackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> colors;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.colors,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress <= 0) return;
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: start,
          endAngle: start + 2 * math.pi,
          colors: [...colors, colors.first],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.colors != colors;
}

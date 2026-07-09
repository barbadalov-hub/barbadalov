import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Procedural animated canvas backgrounds — the "living" layer behind module
/// screens (falling coins for Money, an ECG pulse for Health, drifting glow
/// orbs for Goals/Diet). Pure CustomPainter: no video assets, no plugins, runs
/// on every platform, and repaints are driven by the controller (no setState).
enum BackdropStyle { coins, pulse, orbs, galaxy }

class AnimatedBackdrop extends StatefulWidget {
  final BackdropStyle style;
  final Color color;
  final Widget child;

  /// Draw the cosmic starfield beneath the style layer — on by default so the
  /// whole app lives in the same deep-space world.
  final bool stars;

  const AnimatedBackdrop({
    required this.style,
    required this.color,
    required this.child,
    this.stars = true,
    super.key,
  });

  @override
  State<AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.stars && widget.style != BackdropStyle.galaxy)
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _StarsPainter(_controller)),
            ),
          ),
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: switch (widget.style) {
                BackdropStyle.coins =>
                  _CoinsPainter(_controller, widget.color),
                BackdropStyle.pulse =>
                  _PulsePainter(_controller, widget.color),
                BackdropStyle.orbs => _OrbsPainter(_controller, widget.color),
                BackdropStyle.galaxy =>
                  _GalaxyPainter(_controller, widget.color),
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

/// Deterministic pseudo-random per particle index (no per-frame allocation).
double _hash(int i, int salt) =>
    (math.sin(i * 127.1 + salt * 311.7) * 43758.5453).abs() % 1.0;

/// Falling, gently spinning coins (Money).
class _CoinsPainter extends CustomPainter {
  final Animation<double> t;
  final Color color;
  _CoinsPainter(this.t, this.color) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    const count = 14;
    final fill = Paint()..color = color.withValues(alpha: 0.10);
    final rim = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    for (var i = 0; i < count; i++) {
      final speed = 0.35 + _hash(i, 1) * 0.65;
      final phase = (t.value * speed + _hash(i, 2)) % 1.0;
      final x = _hash(i, 3) * size.width;
      final y = phase * (size.height + 60) - 30;
      final r = 8 + _hash(i, 4) * 10;
      // Spin: squash horizontally like a turning coin.
      final squash =
          (math.sin((t.value * 6 + i) * math.pi) * 0.6).abs() + 0.4;

      canvas.save();
      canvas.translate(x, y);
      canvas.scale(squash, 1);
      canvas.drawCircle(Offset.zero, r, fill);
      canvas.drawCircle(Offset.zero, r, rim);
      canvas.drawCircle(Offset.zero, r * 0.55, rim);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CoinsPainter old) => false;
}

/// A scrolling ECG heartbeat line (Health).
class _PulsePainter extends CustomPainter {
  final Animation<double> t;
  final Color color;
  _PulsePainter(this.t, this.color) : super(repaint: t);

  static double _wave(double x) {
    // One heartbeat over x ∈ [0,1): flat → spike up → dip → flat.
    final p = x % 1.0;
    if (p < 0.32 || p > 0.62) return 0;
    if (p < 0.40) return (p - 0.32) / 0.08 * 0.25; // ramp
    if (p < 0.46) return 0.25 - (p - 0.40) / 0.06 * 1.25; // spike up (neg y)
    if (p < 0.52) return -1.0 + (p - 0.46) / 0.06 * 1.55; // fall through
    return 0.55 - (p - 0.52) / 0.10 * 0.55; // recover
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;

    for (var row = 0; row < 2; row++) {
      final baseY = size.height * (row == 0 ? 0.30 : 0.72);
      final amp = size.height * 0.10;
      final path = Path()..moveTo(0, baseY);
      final shift = t.value * (row == 0 ? 1.0 : -1.0);
      for (double x = 0; x <= size.width; x += 4) {
        final u = x / size.width * 2 + shift;
        path.lineTo(x, baseY + _wave(u) * amp);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulsePainter old) => false;
}

/// The shared starfield: twinkling stars in three depth layers plus a periodic
/// shooting star. Drawn beneath every module backdrop so the whole app shares
/// one cosmic world.
class _StarsPainter extends CustomPainter {
  final Animation<double> t;
  _StarsPainter(this.t) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    const count = 55;
    for (var i = 0; i < count; i++) {
      final x = _hash(i, 31) * size.width;
      final y = _hash(i, 32) * size.height;
      final layer = i % 3;
      final twinkle =
          0.5 + 0.5 * math.sin(t.value * 2 * math.pi * (1 + layer) + i * 1.7);
      canvas.drawCircle(
        Offset(x, y),
        0.6 + layer * 0.5,
        Paint()..color = Colors.white.withValues(alpha: 0.08 + 0.18 * twinkle),
      );
    }

    final phase = (t.value * 3) % 1.0;
    if (phase < 0.18) {
      final p = phase / 0.18;
      final sx = size.width * (0.15 + 0.7 * _hash((t.value * 3).floor(), 33));
      final sy = size.height * 0.10;
      final head = Offset(sx + p * 160, sy + p * 90);
      final tail = Offset(head.dx - 46, head.dy - 26);
      canvas.drawLine(
        tail,
        head,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.5 * (1 - p)),
            ],
          ).createShader(Rect.fromPoints(tail, head))
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter old) => false;
}

/// Deep space: a twinkling starfield, drifting nebula clouds and a periodic
/// shooting star — the cosmic backdrop for the home screen.
class _GalaxyPainter extends CustomPainter {
  final Animation<double> t;
  final Color color;
  _GalaxyPainter(this.t, this.color) : super(repaint: t);

  static const _nebulaColors = [
    Color(0xFF7B5CFF), // violet
    Color(0xFF2E7CF6), // deep blue
    Color(0xFF19C2B8), // teal
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // --- Nebula clouds: huge, blurred, slowly breathing radial glows.
    for (var i = 0; i < 3; i++) {
      final drift = t.value * 2 * math.pi * (0.15 + 0.1 * i);
      final cx = size.width * (0.2 + 0.3 * i) + math.cos(drift + i) * 40;
      final cy = size.height * (0.15 + 0.3 * _hash(i, 21)) +
          math.sin(drift * 0.8 + i) * 30;
      final r = size.shortestSide * (0.35 + 0.1 * _hash(i, 22)) *
          (1 + 0.08 * math.sin(t.value * 2 * math.pi + i));
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = _nebulaColors[i].withValues(alpha: 0.055)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
      );
    }

    // --- Stars: fixed positions, twinkling opacity, three depth layers.
    const count = 70;
    for (var i = 0; i < count; i++) {
      final x = _hash(i, 31) * size.width;
      final y = _hash(i, 32) * size.height;
      final layer = i % 3;
      final baseR = 0.6 + layer * 0.5;
      final twinkle =
          0.5 + 0.5 * math.sin(t.value * 2 * math.pi * (1 + layer) + i * 1.7);
      canvas.drawCircle(
        Offset(x, y),
        baseR,
        Paint()
          ..color =
              Colors.white.withValues(alpha: 0.10 + 0.22 * twinkle),
      );
    }

    // --- A shooting star crossing every cycle.
    final phase = (t.value * 3) % 1.0;
    if (phase < 0.18) {
      final p = phase / 0.18;
      final sx = size.width * (0.15 + 0.7 * _hash((t.value * 3).floor(), 33));
      final sy = size.height * 0.12;
      final head = Offset(sx + p * 160, sy + p * 90);
      final tail = Offset(head.dx - 46, head.dy - 26);
      canvas.drawLine(
        tail,
        head,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.55 * (1 - p)),
            ],
          ).createShader(Rect.fromPoints(tail, head))
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter old) => false;
}

/// Slow drifting glow orbs (Goals / Diet) — calm, dreamy depth.
class _OrbsPainter extends CustomPainter {
  final Animation<double> t;
  final Color color;
  _OrbsPainter(this.t, this.color) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    const count = 9;
    for (var i = 0; i < count; i++) {
      final angle = t.value * 2 * math.pi * (0.2 + _hash(i, 5) * 0.3) +
          _hash(i, 6) * math.pi * 2;
      final cx = _hash(i, 7) * size.width + math.cos(angle) * 30;
      final cy = _hash(i, 8) * size.height + math.sin(angle) * 24;
      final r = 26 + _hash(i, 9) * 46;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.05 + _hash(i, 10) * 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbsPainter old) => false;
}

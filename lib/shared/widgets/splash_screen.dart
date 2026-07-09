import 'package:flutter/material.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';

/// The cosmos boot screen: an orbiting mark that scales in over the galaxy
/// backdrop with the wordmark, shown briefly before the app gate. Pure Dart —
/// renders identically on Windows, web, Android and iOS.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mark = CurvedAnimation(
      parent: _c,
      curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
    );
    final text = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.4, 1, curve: Curves.easeOut),
    );

    return Scaffold(
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: mark,
                child: FadeTransition(
                  opacity: mark,
                  child: const _CosmosMark(size: 128),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: text,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(text),
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (r) => const LinearGradient(
                          colors: [Color(0xFF7BF7FF), Color(0xFF7B5CFF)],
                        ).createShader(r),
                        child: const Text(
                          'LifeOS',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('splash.tagline'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The brand mark: a glowing orb inside a gradient ring with an orbiting dot —
/// the same motif as the launcher icon.
class _CosmosMark extends StatelessWidget {
  final double size;
  const _CosmosMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // Faint orbit.
    canvas.drawCircle(
      c,
      r * 0.94,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.012
        ..color = const Color(0xFFB4C8FF).withValues(alpha: 0.35),
    );

    // Orbiting planet.
    final planet = Offset(
      c.dx + r * 0.94 * 0.71,
      c.dy - r * 0.94 * 0.71,
    );
    canvas.drawCircle(planet, r * 0.10, Paint()..color = const Color(0xFF7BF7FF));

    // Main gradient ring.
    final ringRect = Rect.fromCircle(center: c, radius: r * 0.64);
    canvas.drawArc(
      ringRect,
      0,
      6.2832,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.17
        ..shader = const LinearGradient(
          colors: [Color(0xFF7BF7FF), Color(0xFF7B5CFF)],
        ).createShader(ringRect),
    );

    // Glowing center orb.
    final orbRect = Rect.fromCircle(center: c, radius: r * 0.36);
    canvas.drawCircle(
      c,
      r * 0.36,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFAAF8FF), Color(0xFF6C3CDC)],
        ).createShader(orbRect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

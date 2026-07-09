import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/lifeweeks/domain/life_weeks.dart';
import 'package:lifeos/features/profile/presentation/pages/profile_page.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/glass_card.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';

/// The signature "your life in weeks" grid — one square per week of a ~90-year
/// life, filled up to your age. Makes time feel finite and precious.
class LifeWeeksPage extends ConsumerWidget {
  const LifeWeeksPage({super.key});

  /// Cosmos palette used per decade of lived weeks.
  static const _decade = [
    Color(0xFFA79BFF), Color(0xFF8E7BFF), Color(0xFF6D8BFF), Color(0xFF4FB0FF),
    Color(0xFF3BC9C9), Color(0xFF3BD07A), Color(0xFFF5C542), Color(0xFFF59B42),
    Color(0xFFF5576C),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('weeks.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: profile == null
            ? _NeedsProfile(
                onOpen: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
                ),
              )
            : _Weeks(life: LifeWeeks(ageYears: profile.age)),
      ),
    );
  }
}

class _Weeks extends StatelessWidget {
  final LifeWeeks life;
  const _Weeks({required this.life});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GradientCard(
          colors: const [Color(0xFF7F53AC), Color(0xFF647DEE)],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.trp('weeks.lived', {'n': life.percentLived}),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                context.trp('weeks.summary', {
                  'lived': life.weeksLived,
                  'left': life.weeksLeft,
                  'years': life.yearsLeft,
                }),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(context.tr('weeks.tagline'),
                  style: const TextStyle(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('weeks.gridTitle'),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(context.tr('weeks.legend'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      )),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, c) {
                  const cols = 52;
                  final cell = c.maxWidth / cols;
                  final rows = life.lifeExpectancy;
                  return SizedBox(
                    width: c.maxWidth,
                    height: rows * cell,
                    child: CustomPaint(
                      painter: _WeeksPainter(
                        life: life,
                        cell: cell,
                        decade: LifeWeeksPage._decade,
                        future: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(context.tr('weeks.footer'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                )),
      ],
    );
  }
}

class _WeeksPainter extends CustomPainter {
  final LifeWeeks life;
  final double cell;
  final List<Color> decade;
  final Color future;

  _WeeksPainter({
    required this.life,
    required this.cell,
    required this.decade,
    required this.future,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gap = cell * 0.18;
    final radius = Radius.circular(cell * 0.22);
    final lived = life.weeksLived;
    for (var i = 0; i < life.totalWeeks; i++) {
      final row = i ~/ 52;
      final col = i % 52;
      final rect = Rect.fromLTWH(
        col * cell + gap / 2,
        row * cell + gap / 2,
        cell - gap,
        cell - gap,
      );
      final Paint paint;
      if (i == lived) {
        // Current week — bright with a soft glow.
        paint = Paint()..color = Colors.white;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(gap * 0.4), radius),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      } else if (i < lived) {
        paint = Paint()..color = decade[(row ~/ 10).clamp(0, decade.length - 1)];
      } else {
        paint = Paint()..color = future;
      }
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeeksPainter old) =>
      old.life.weeksLived != life.weeksLived || old.cell != cell;
}

class _NeedsProfile extends StatelessWidget {
  final VoidCallback onOpen;
  const _NeedsProfile({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏳', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(context.tr('weeks.needsProfile'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.person),
              label: Text(context.tr('wellness.fillProfile')),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/achievements/domain/achievement.dart';
import 'package:lifeos/features/achievements/presentation/providers/achievements_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';
import 'package:lifeos/shared/widgets/motion.dart';

/// The trophy wall: every badge across the app, grouped by pillar, with progress
/// on the ones still locked. Gamifies consistent use of LifeOS.
class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  static const _order = [
    AchievementCategory.habits,
    AchievementCategory.health,
    AchievementCategory.money,
    AchievementCategory.mind,
    AchievementCategory.meta,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(achievementsProvider);
    final unlocked = all.where((s) => s.unlocked).length;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('ach.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GradientCard(
              colors: const [Color(0xFFF7971E), Color(0xFFFFD200)],
              child: Row(
                children: [
                  GradientRing(
                    progress: all.isEmpty ? 0 : unlocked / all.length,
                    size: 78,
                    strokeWidth: 9,
                    colors: const [Colors.white, Color(0xFFFFF2C2)],
                    center: Text('$unlocked',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🏅 ${context.tr('ach.title')}',
                            style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(
                          context.trp('ach.unlockedOf',
                              {'n': unlocked, 'total': all.length}),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final cat in _order)
              _CategorySection(
                category: cat,
                statuses: all.where((s) => s.def.category == cat).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final AchievementCategory category;
  final List<AchievementStatus> statuses;
  const _CategorySection({required this.category, required this.statuses});

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(context.tr('ach.cat.${category.name}'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
          children: [for (final s in statuses) _BadgeTile(status: s)],
        ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final AchievementStatus status;
  const _BadgeTile({required this.status});

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(status.def.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(ctx.tr(status.def.titleKey),
                textAlign: TextAlign.center,
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(ctx.tr(status.def.descKey),
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (status.unlocked)
              Text('✅ ${ctx.tr('ach.done')}',
                  style: const TextStyle(
                      color: Color(0xFF2E9E6B), fontWeight: FontWeight.w700))
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: status.ratio,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ctx.trp('ach.progress', {
                  'cur': _fmt(status.current),
                  'goal': _fmt(status.def.goal),
                }),
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = status.unlocked;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: unlocked
          ? const Color(0xFFF7971E).withValues(alpha: 0.16)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unlocked
                  ? const Color(0xFFF7971E).withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              Opacity(
                opacity: unlocked ? 1 : 0.35,
                child: Text(status.def.emoji,
                    style: const TextStyle(fontSize: 38)),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(status.def.titleKey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: unlocked
                      ? null
                      : scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              if (unlocked)
                const Icon(Icons.verified, color: Color(0xFFF7971E), size: 20)
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: status.ratio,
                      minHeight: 5,
                      backgroundColor: scheme.surfaceContainerHighest,
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

String _fmt(num n) => n == n.roundToDouble() ? n.round().toString() : '$n';

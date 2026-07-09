import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';
import 'package:lifeos/shared/widgets/motion.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// The complete safe-training guide (A→Z): pre-workout checklist, personal
/// heart-rate zones computed from the profile, ten expert sections (warm-up,
/// cool-down, hydration, food, recovery, contraindications, technique,
/// progression, structure, breathing) and the hard "never do this" list —
/// distilled from standard WHO/ACSM-style recommendations.
class WorkoutGuidePage extends ConsumerStatefulWidget {
  const WorkoutGuidePage({super.key});

  @override
  ConsumerState<WorkoutGuidePage> createState() => _WorkoutGuidePageState();
}

class _WorkoutGuidePageState extends ConsumerState<WorkoutGuidePage> {
  final Set<int> _checked = {};

  static const _sections = [
    ('🔥', 'guide.warmup'),
    ('🧊', 'guide.cooldown'),
    ('💧', 'guide.water'),
    ('🍽️', 'guide.food'),
    ('😴', 'guide.recovery'),
    ('🩺', 'guide.contra'),
    ('🏋️', 'guide.technique'),
    ('📈', 'guide.progress'),
    ('🌬️', 'guide.breathing'),
    ('📋', 'guide.structure'),
  ];

  static const _reds = [
    'guide.red1',
    'guide.red2',
    'guide.red3',
    'guide.red4',
    'guide.red5',
    'guide.red6',
  ];

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('guide.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.pulse,
        color: LifeColors.health,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Pre-workout checklist -----------------------------------
            FadeSlideIn(
              index: 0,
              child: GradientCard(
                colors: LifeGradients.health,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('guide.checklist'),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.white)),
                    const SizedBox(height: 6),
                    for (var i = 1; i <= 4; i++)
                      InkWell(
                        onTap: () => setState(() => _checked.contains(i)
                            ? _checked.remove(i)
                            : _checked.add(i)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                _checked.contains(i)
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(context.tr('guide.check$i'),
                                    style: const TextStyle(
                                        color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_checked.length == 4)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(context.tr('guide.checkDone'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // --- Personal heart-rate zones -------------------------------
            FadeSlideIn(
              index: 1,
              child: SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🫀 ${context.tr('guide.zones')}',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (profile == null)
                      Text(context.tr('guide.zonesNoProfile'))
                    else ...[
                      Text(context.trp('guide.zonesMax',
                          {'max': 220 - profile.age, 'age': profile.age})),
                      const SizedBox(height: 8),
                      _zoneRow(context, 'guide.zone1', 0.50, 0.60,
                          220 - profile.age, const Color(0xFF3BA7FF)),
                      _zoneRow(context, 'guide.zone2', 0.60, 0.70,
                          220 - profile.age, LifeColors.finance),
                      _zoneRow(context, 'guide.zone3', 0.70, 0.80,
                          220 - profile.age, LifeColors.goals),
                      _zoneRow(context, 'guide.zone4', 0.80, 0.90,
                          220 - profile.age, const Color(0xFFFF8C42)),
                      _zoneRow(context, 'guide.zone5', 0.90, 1.00,
                          220 - profile.age, LifeColors.financeDanger),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // --- The ten sections -----------------------------------------
            for (var i = 0; i < _sections.length; i++) ...[
              FadeSlideIn(
                index: 2 + i,
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_sections[i].$1} ${context.tr('${_sections[i].$2}.t')}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(context.tr('${_sections[i].$2}.b')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // --- The hard NOs ---------------------------------------------
            SectionCard(
              color: LifeColors.financeDanger.withValues(alpha: 0.10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🚫 ${context.tr('guide.never')}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: LifeColors.financeDanger)),
                  const SizedBox(height: 8),
                  for (final key in _reds)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✗ ',
                              style: TextStyle(
                                  color: LifeColors.financeDanger,
                                  fontWeight: FontWeight.w800)),
                          Expanded(child: Text(context.tr(key))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('guide.disclaimer'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoneRow(BuildContext context, String key, double lo, double hi,
      int max, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(context.tr(key))),
          Text(
            '${(max * lo).round()}–${(max * hi).round()} bpm',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

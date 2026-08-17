import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/insights/presentation/pages/insights_page.dart';
import 'package:lifeos/features/insights/presentation/providers/insights_providers.dart';
import 'package:lifeos/features/lifeweeks/presentation/pages/life_weeks_page.dart';
import 'package:lifeos/features/mind/domain/mood.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/rooms/presentation/widgets/room_scaffold.dart';
import 'package:lifeos/features/telescope/domain/period_stats.dart';
import 'package:lifeos/features/telescope/presentation/providers/telescope_providers.dart';
import 'package:lifeos/features/wrapped/presentation/pages/wrapped_page.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// The telescope: one life, read at different distances. Sliding the zoom does
/// not just filter — it changes what the app talks about, from this week's
/// numbers out to the records of all time.
class TelescopePage extends ConsumerWidget {
  const TelescopePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoom = ref.watch(timeZoomProvider);
    final stats = ref.watch(periodStatsProvider);
    final insights = ref.watch(insightsProvider);
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('zoom.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            SegmentedButton<TimeZoom>(
              showSelectedIcon: false,
              segments: [
                for (final z in TimeZoom.values)
                  ButtonSegment(value: z, label: Text(context.tr(z.labelKey))),
              ],
              selected: {zoom},
              onSelectionChanged: (s) =>
                  ref.read(timeZoomProvider.notifier).state = s.first,
            ),
            const SizedBox(height: 16),
            if (!stats.hasData)
              SectionCard(
                child: Column(
                  children: [
                    const Text('🔭', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 10),
                    Text(context.tr('zoom.empty'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              )
            else ...[
              RoomVoice(text: _voice(context, stats, insights)),
              const SizedBox(height: 14),
              _StatGrid(stats: stats, lang: lang),
              if (zoom == TimeZoom.all) ...[
                const SizedBox(height: 14),
                _Records(insights: insights, stats: stats, lang: lang),
              ],
            ],
            const SizedBox(height: 16),
            _Shortcut(
              emoji: '🔮',
              title: context.tr('insight.title'),
              subtitle: context.tr('insight.moreSub'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const InsightsPage()),
              ),
            ),
            const SizedBox(height: 10),
            _Shortcut(
              emoji: '✨',
              title: context.tr('wrapped.title'),
              subtitle: context.tr('wrapped.moreSub'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const WrappedPage()),
              ),
            ),
            const SizedBox(height: 10),
            _Shortcut(
              emoji: '⏳',
              title: context.tr('weeks.title'),
              subtitle: context.tr('weeks.moreSub'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LifeWeeksPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The sentence that opens the window — a verdict about the stretch, not a
  /// repetition of the tiles under it.
  String _voice(
      BuildContext context, PeriodStats s, InsightsData insights) {
    if (s.zoom == TimeZoom.all) {
      return context.trp('zoom.voiceAll', {'n': s.daysTracked});
    }
    if (s.moodDays >= 3 && s.avgMood >= 4) {
      return context.trp('zoom.voiceGoodMood',
          {'m': s.avgMood.toStringAsFixed(1), 'n': s.daysTracked});
    }
    if (s.netMinor < 0) {
      return context.trp(
          'zoom.voiceOverspent', {'v': Money(-s.netMinor).format()});
    }
    if (s.avgSleep > 0 && s.avgSleep < 7) {
      return context.trp(
          'zoom.voiceShortSleep', {'h': s.avgSleep.toStringAsFixed(1)});
    }
    return context.trp('zoom.voiceSteady', {'n': s.daysTracked});
  }
}

/// The window's numbers as a compact bento of tiles.
class _StatGrid extends StatelessWidget {
  final PeriodStats stats;
  final String lang;
  const _StatGrid({required this.stats, required this.lang});

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.decimalPattern(lang);
    final tiles = <(String, String, String)>[
      if (stats.incomeMinor > 0 || stats.spentMinor > 0)
        (
          context.tr('wrapped.lblNet'),
          '${stats.netMinor >= 0 ? '+' : ''}${Money(stats.netMinor).format()}',
          '💰'
        ),
      if (stats.spentMinor > 0)
        (context.tr('money.spent'), Money(stats.spentMinor).format(), '💸'),
      if (stats.totalSteps > 0)
        (context.tr('health.steps'), nf.format(stats.totalSteps), '👟'),
      if (stats.avgSleep > 0)
        (
          context.tr('report.avgSleep'),
          context.trp('report.hours', {'n': stats.avgSleep.toStringAsFixed(1)}),
          '😴'
        ),
      if (stats.moodDays > 0)
        (
          context.tr('insight.lblMoodShort'),
          stats.avgMood.toStringAsFixed(1),
          moodFace(stats.avgMood.round())
        ),
      if (stats.topCategoryId != null)
        (
          context.tr('wrapped.topCat'),
          context.tr('cat.${DefaultCategories.byId(stats.topCategoryId!).id}'),
          DefaultCategories.byId(stats.topCategoryId!).emoji
        ),
      (
        context.tr('insight.trackedDays'),
        context.trp('insight.days', {'n': stats.daysTracked}),
        '🗓️'
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        const gap = 10.0;
        final w = (c.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (label, value, emoji) in tiles)
              SizedBox(
                width: w,
                child: SectionCard(
                  padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Theme.of(context).colorScheme.outline),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(value,
                            style: const TextStyle(
                                fontSize: 19, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// At full zoom-out the app stops reporting and starts remembering: the peaks
/// and streaks that only exist across all of time.
class _Records extends StatelessWidget {
  final InsightsData insights;
  final PeriodStats stats;
  final String lang;
  const _Records(
      {required this.insights, required this.stats, required this.lang});

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.decimalPattern(lang);
    final df = DateFormat.yMMMd(lang);
    final rows = <(String, String, String)>[
      if (insights.bestStreak > 0)
        (
          '🔥',
          context.tr('insight.bestStreak'),
          context.trp('insight.days', {'n': insights.bestStreak})
        ),
      if (insights.loggingStreak > 1)
        (
          '⚡',
          context.tr('insight.loggingStreak'),
          context.trp('insight.days', {'n': insights.loggingStreak})
        ),
      if (stats.peakSteps > 0)
        ('👟', context.tr('insight.peakSteps'), nf.format(stats.peakSteps)),
      if (insights.bestMoodDay != null)
        (
          moodFace(insights.bestMoodDay!.mood),
          context.tr('insight.bestMood'),
          df.format(insights.bestMoodDay!.date)
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('insight.highlights'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 18),
            Row(
              children: [
                Text(rows[i].$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(child: Text(rows[i].$2)),
                Text(rows[i].$3,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Shortcut({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        )),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

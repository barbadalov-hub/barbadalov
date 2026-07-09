import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/insights/domain/insight_engine.dart';
import 'package:lifeos/features/insights/domain/mood_patterns.dart';
import 'package:lifeos/features/insights/presentation/providers/insights_providers.dart';
import 'package:lifeos/features/mind/domain/mood.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';
import 'package:lifeos/shared/widgets/section_card.dart';
import 'package:lifeos/shared/widgets/share_card.dart';

/// Full weekday name for [weekday] (1..7) in [lang]. Jan 2024 starts on Monday.
String weekdayNameFor(String lang, int weekday) {
  final name = DateFormat.EEEE(lang).format(DateTime(2024, 1, weekday));
  return name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
}

/// The one-line share highlights for the current insights, localized.
List<String> insightShareLines(BuildContext context, InsightsData d, String lang) {
  final out = <String>[];
  if (d.correlations.isNotEmpty) {
    final c = d.correlations.first;
    out.add(context.tr('insight.${c.driver.name}.${c.positive ? 'pos' : 'neg'}'));
  }
  if (d.trend != null) {
    out.add(context.tr(switch (d.trend!) {
      MoodTrend.rising => 'insight.trendRising',
      MoodTrend.steady => 'insight.trendSteady',
      MoodTrend.falling => 'insight.trendFalling',
    }));
  }
  if (d.bestWeekday != null) {
    out.add(context.trp('insight.bestWeekday',
        {'day': weekdayNameFor(lang, d.bestWeekday!.weekday)}));
  }
  final lift = d.activityImpacts.where((c) => c.delta > 0).firstOrNull;
  final act = lift == null ? null : MoodActivities.byId(lift.activityId);
  if (act != null) {
    out.add('${act.emoji} ${context.trp('insight.shareLift', {'name': context.tr(act.labelKey)})}');
  }
  return out;
}

/// "Life Patterns" — honest, cross-pillar correlations between daily mood and
/// sleep/steps/water/spending, plus single-metric highlights. Non-medical.
class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  static const _emoji = {
    InsightDriver.sleep: '😴',
    InsightDriver.steps: '👟',
    InsightDriver.water: '💧',
    InsightDriver.spending: '💸',
    InsightDriver.stress: '😰',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(insightsProvider);
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('insight.title')),
        actions: [
          if (data.hasAny)
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: context.tr('wrapped.share'),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (_) => _InsightShareSheet(data: data, lang: lang),
              ),
            ),
        ],
      ),
      body: AnimatedBackdrop(
        style: BackdropStyle.orbs,
        color: const Color(0xFF7F53AC),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GradientCard(
              colors: LifeGradients.mind,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔮 ${context.tr('insight.heroTitle')}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(
                    context.trp('insight.tracked', {'n': data.trackedDays}),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (!data.hasAny)
              _Empty()
            else ...[
              if (data.correlations.isNotEmpty) ...[
                Text(context.tr('insight.patterns'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final i in data.correlations)
                  _CorrelationCard(insight: i),
              ] else
                SectionCard(
                  child: Row(
                    children: [
                      const Text('🌱', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(context.tr('insight.needMore'))),
                    ],
                  ),
                ),

              if (data.activityImpacts.isNotEmpty ||
                  data.bestWeekday != null ||
                  data.trend != null) ...[
                const SizedBox(height: 16),
                Text(context.tr('insight.moodPatterns'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _MoodPatterns(data: data, lang: lang),
              ],

              const SizedBox(height: 16),
              Text(context.tr('insight.highlights'),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _Highlights(data: data, lang: lang),
            ],

            const SizedBox(height: 20),
            Text(
              context.tr('insight.disclaimer'),
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
}

class _CorrelationCard extends StatelessWidget {
  final LifeInsight insight;
  const _CorrelationCard({required this.insight});

  String _strengthKey(double s) =>
      s < 0.4 ? 'insight.weak' : (s < 0.6 ? 'insight.medium' : 'insight.strong');

  @override
  Widget build(BuildContext context) {
    final color = insight.positive
        ? const Color(0xFF2E9E6B)
        : const Color(0xFFE08A2B);
    final sentence =
        'insight.${insight.driver.name}.${insight.positive ? 'pos' : 'neg'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(InsightsPage._emoji[insight.driver] ?? '•',
                    style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(context.tr(sentence),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: insight.strength,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.tr(_strengthKey(insight.strength)),
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                Text(
                  context.trp('insight.basedOn', {'n': insight.samples}),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Mood patterns (Insights v2): two-week trend, happiest weekday, and which
/// activities lift or lower mood.
class _MoodPatterns extends StatelessWidget {
  final InsightsData data;
  final String lang;
  const _MoodPatterns({required this.data, required this.lang});

  @override
  Widget build(BuildContext context) {
    final lifts =
        data.activityImpacts.where((c) => c.delta > 0).take(3).toList();
    final lowers =
        data.activityImpacts.where((c) => c.delta < 0).take(3).toList();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.trend != null) ...[
            _trendRow(context, data.trend!),
            const SizedBox(height: 10),
          ],
          if (data.bestWeekday != null) ...[
            Row(
              children: [
                const Text('🗓️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(context.trp('insight.bestWeekday', {
                    'day': _weekdayName(data.bestWeekday!.weekday),
                  })),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (lifts.isNotEmpty) ...[
            Text(context.tr('insight.liftsMood'),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Color(0xFF2E9E6B))),
            const SizedBox(height: 6),
            for (final c in lifts) _activityRow(context, c),
          ],
          if (lowers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(context.tr('insight.lowersMood'),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Color(0xFFE08A2B))),
            const SizedBox(height: 6),
            for (final c in lowers) _activityRow(context, c),
          ],
        ],
      ),
    );
  }

  Widget _trendRow(BuildContext context, MoodTrend trend) {
    final key = switch (trend) {
      MoodTrend.rising => 'insight.trendRising',
      MoodTrend.steady => 'insight.trendSteady',
      MoodTrend.falling => 'insight.trendFalling',
    };
    return Text(context.tr(key),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600));
  }

  Widget _activityRow(BuildContext context, MoodCorrelation c) {
    final act = MoodActivities.byId(c.activityId);
    if (act == null) return const SizedBox.shrink();
    final sign = c.delta > 0 ? '+' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(act.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(context.tr(act.labelKey))),
          Text('$sign${c.delta.toStringAsFixed(1)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: c.delta > 0
                    ? const Color(0xFF2E9E6B)
                    : const Color(0xFFE08A2B),
              )),
        ],
      ),
    );
  }

  String _weekdayName(int weekday) => weekdayNameFor(lang, weekday);
}

class _Highlights extends StatelessWidget {
  final InsightsData data;
  final String lang;
  const _Highlights({required this.data, required this.lang});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.MMMMd(lang);
    final rows = <Widget>[];

    if (data.bestMoodDay != null) {
      rows.add(_row(
        context,
        moodFace(data.bestMoodDay!.mood),
        context.tr('insight.bestMood'),
        df.format(data.bestMoodDay!.date),
      ));
    }
    if (data.peakStepsDay != null) {
      rows.add(_row(
        context,
        '👟',
        context.tr('insight.peakSteps'),
        '${NumberFormat.decimalPattern(lang).format(data.peakStepsDay!.steps)} · ${df.format(data.peakStepsDay!.date)}',
      ));
    }
    if (data.bestStreak > 0) {
      rows.add(_row(
        context,
        '🔥',
        context.tr('insight.bestStreak'),
        context.trp('insight.days', {'n': data.bestStreak}),
      ));
    }
    if (data.loggingStreak > 1) {
      rows.add(_row(
        context,
        '⚡',
        context.tr('insight.loggingStreak'),
        context.trp('insight.days', {'n': data.loggingStreak}),
      ));
    }
    rows.add(_row(
      context,
      '🗓️',
      context.tr('insight.trackedDays'),
      context.trp('insight.days', {'n': data.trackedDays}),
    ));

    return SectionCard(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 18),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        children: [
          const Text('🔮', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(context.tr('insight.emptyTitle'),
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(context.tr('insight.empty'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Bottom sheet with a shareable card of the user's top patterns → PNG.
class _InsightShareSheet extends StatefulWidget {
  final InsightsData data;
  final String lang;
  const _InsightShareSheet({required this.data, required this.lang});

  @override
  State<_InsightShareSheet> createState() => _InsightShareSheetState();
}

class _InsightShareSheetState extends State<_InsightShareSheet> {
  final _shareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final lines = insightShareLines(context, widget.data, widget.lang);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _shareKey,
              child: ShareCard(
                emoji: '🔮',
                title: context.tr('insight.shareCardTitle'),
                lines: lines,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => shareBoundaryPng(
                    context, _shareKey, 'lifeos_insights.png',
                    popAfter: true),
                icon: const Icon(Icons.ios_share),
                label: Text(context.tr('wrapped.share')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

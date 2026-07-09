import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/history/domain/monthly_snapshot.dart';
import 'package:lifeos/features/history/presentation/providers/history_providers.dart';
import 'package:lifeos/features/mind/domain/mood.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// The life timeline: every month you've used LifeOS, grouped by year, so you
/// can look back a year — or five — at what was going on.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final months = ref.watch(timelineProvider);
    final locale = Localizations.localeOf(context).languageCode;

    // Group by year (already newest-first).
    final byYear = <int, List<MonthlySnapshot>>{};
    for (final s in months) {
      (byYear[s.year] ??= []).add(s);
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('hist.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: months.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📜', style: TextStyle(fontSize: 44)),
                      const SizedBox(height: 12),
                      Text(context.tr('hist.empty'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(context.tr('hist.emptySub'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  for (final year in byYear.keys)
                    _YearSection(
                      year: year,
                      months: byYear[year]!,
                      locale: locale,
                    ),
                ],
              ),
      ),
    );
  }
}

class _YearSection extends StatelessWidget {
  final int year;
  final List<MonthlySnapshot> months;
  final String locale;
  const _YearSection(
      {required this.year, required this.months, required this.locale});

  @override
  Widget build(BuildContext context) {
    final net = months.fold(0, (s, m) => s + m.netMinor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Text('$year',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              Text(
                '${net >= 0 ? '+' : ''}${Money(net).format()}',
                style: TextStyle(
                  color: net >= 0 ? LifeColors.finance : LifeColors.financeDanger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        for (final m in months)
          _MonthCard(snapshot: m, locale: locale),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _MonthCard extends StatelessWidget {
  final MonthlySnapshot snapshot;
  final String locale;
  const _MonthCard({required this.snapshot, required this.locale});

  @override
  Widget build(BuildContext context) {
    final monthName =
        DateFormat.MMMM(locale).format(DateTime(snapshot.year, snapshot.month));
    return SectionCard(
      onTap: () => _showDetail(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_cap(monthName),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  [
                    if (snapshot.spentMinor > 0)
                      '−${Money(snapshot.spentMinor).format()}',
                    if (snapshot.avgSteps > 0)
                      '👟 ${snapshot.avgSteps}',
                    if (snapshot.avgMood != null)
                      moodFace(snapshot.avgMood!.round()),
                  ].join('  ·  '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final monthName =
        DateFormat.yMMMM(locale).format(DateTime(snapshot.year, snapshot.month));
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_cap(monthName), style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 12),
            GradientCard(
              colors: LifeGradients.finance,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _stat(ctx, ctx.tr('money.income'),
                      Money(snapshot.incomeMinor).format()),
                  _stat(ctx, ctx.tr('money.spent'),
                      Money(snapshot.spentMinor).format()),
                  _stat(
                      ctx,
                      ctx.tr('report.last7').split(' ').first,
                      '${snapshot.netMinor >= 0 ? '+' : ''}'
                          '${Money(snapshot.netMinor).format()}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _row(ctx, '📊', ctx.tr('report.topSpending'),
                snapshot.topCategoryId == null
                    ? '—'
                    : ctx.tr('cat.${snapshot.topCategoryId}')),
            _row(ctx, '😊', ctx.tr('mood.title'),
                snapshot.avgMood == null
                    ? '—'
                    : '${moodFace(snapshot.avgMood!.round())} ${snapshot.avgMood!.toStringAsFixed(1)}/5'),
            _row(ctx, '👟', ctx.tr('report.avgSteps'), '${snapshot.avgSteps}'),
            _row(ctx, '😴', ctx.tr('report.avgSleep'),
                '${snapshot.avgSleep.toStringAsFixed(1)} h'),
            _row(ctx, '⚖️', ctx.tr('report.weightChange').split(' ').first,
                snapshot.weightKg == null
                    ? '—'
                    : '${snapshot.weightKg!.toStringAsFixed(1)} kg'),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      );

  Widget _row(BuildContext context, String emoji, String label, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

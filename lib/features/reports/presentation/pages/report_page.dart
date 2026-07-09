import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/reports/presentation/providers/report_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';
import 'package:lifeos/shared/widgets/section_card.dart';
import 'package:lifeos/shared/widgets/share_card.dart';

/// A one-screen recap of the last 7 days across money, health and habits.
class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(weeklyReportProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('report.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: context.tr('wrapped.share'),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (_) => _ReportShareSheet(report: r),
            ),
          ),
        ],
      ),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            GradientCard(
              colors: LifeGradients.finance,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('report.last7'),
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(
                    '${r.net.minorUnits >= 0 ? '+' : ''}${r.net.format()}',
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _stat(context, context.tr('money.income'),
                          r.income.format()),
                      _stat(context, context.tr('money.spent'),
                          r.spent.format()),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (r.topCategories.isNotEmpty)
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('report.topSpending'),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final (cat, amount) in r.topCategories)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text(cat.emoji),
                            const SizedBox(width: 8),
                            Expanded(child: Text(context.tr('cat.${cat.id}'))),
                            Text(amount.format(),
                                style:
                                    const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('report.health'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _metric(context, '👟', context.tr('report.avgSteps'),
                      '${r.avgSteps}'),
                  _metric(context, '💧', context.tr('report.avgWater'),
                      context.trp('report.glasses', {'n': r.avgWater.toStringAsFixed(1)})),
                  _metric(context, '😴', context.tr('report.avgSleep'),
                      context.trp('report.hours', {'n': r.avgSleep.toStringAsFixed(1)})),
                  if (r.weightDelta != null)
                    _metric(
                        context,
                        '⚖️',
                        context.tr('report.weightChange'),
                        '${r.weightDelta! >= 0 ? '+' : ''}${r.weightDelta!.toStringAsFixed(1)} kg'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('report.habits'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _metric(context, '✅', context.tr('report.habitsDone'),
                      '${r.habitsDone}/${r.habitsTotal}'),
                  _metric(context, '🔥', context.tr('report.bestStreak'),
                      context.trp('report.days', {'n': r.bestStreak})),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }

  Widget _metric(
      BuildContext context, String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Bottom sheet with a shareable card of the week's numbers → PNG.
class _ReportShareSheet extends StatefulWidget {
  final WeeklyReport report;
  const _ReportShareSheet({required this.report});

  @override
  State<_ReportShareSheet> createState() => _ReportShareSheetState();
}

class _ReportShareSheetState extends State<_ReportShareSheet> {
  final _shareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    final rows = <(String, String, String)>[
      ('💰', context.tr('wrapped.lblNet'),
          '${r.net.minorUnits >= 0 ? '+' : ''}${r.net.format()}'),
      ('💸', context.tr('money.spent'), r.spent.format()),
      ('👟', context.tr('wrapped.lblSteps'), '${r.avgSteps}'),
      ('😴', context.tr('report.avgSleep'),
          context.trp('report.hours', {'n': r.avgSleep.toStringAsFixed(1)})),
      ('✅', context.tr('report.habits'), '${r.habitsDone}/${r.habitsTotal}'),
      if (r.bestStreak > 0)
        ('🔥', context.tr('wrapped.lblStreak'),
            context.trp('report.days', {'n': r.bestStreak})),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _shareKey,
              child: ShareCard(
                emoji: '📊',
                title: context.tr('report.shareTitle'),
                rows: rows,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    shareBoundaryPng(context, _shareKey, 'lifeos_week.png',
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


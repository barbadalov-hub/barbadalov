import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/wellness/domain/cycle.dart';
import 'package:lifeos/features/wellness/domain/cycle_log.dart';
import 'package:lifeos/features/wellness/presentation/providers/wellness_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';
import 'package:lifeos/shared/widgets/motion.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// Flo-style menstrual-cycle tracker: setup questionnaire, then a dashboard
/// with the current phase, next-period countdown and fertile window.
class CyclePage extends ConsumerWidget {
  const CyclePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(cycleProvider);
    final prediction = ref.watch(cyclePredictionProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('cycle.title')),
        actions: [
          if (data != null)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: context.tr('cycle.edit'),
              onPressed: () => _editSetup(context, ref, data),
            ),
        ],
      ),
      body: AnimatedBackdrop(
        style: BackdropStyle.orbs,
        color: const Color(0xFFF5576C),
        child: (data == null || prediction == null)
            ? _CycleSetup(onSaved: (d) => ref.read(cycleProvider.notifier).save(d))
            : _CycleDashboard(
                data: data,
                prediction: prediction,
                onPeriodStarted: () =>
                    ref.read(cycleProvider.notifier).logPeriodStart(),
              ),
      ),
    );
  }

  Future<void> _editSetup(
      BuildContext context, WidgetRef ref, CycleData data) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _CycleSetup(
          initial: data,
          onSaved: (d) {
            ref.read(cycleProvider.notifier).save(d);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

class _CycleDashboard extends StatelessWidget {
  final CycleData data;
  final CyclePrediction prediction;
  final VoidCallback onPeriodStarted;

  const _CycleDashboard({
    required this.data,
    required this.prediction,
    required this.onPeriodStarted,
  });

  @override
  Widget build(BuildContext context) {
    final p = prediction;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        GradientCard(
          colors: LifeGradients.health,
          child: Row(
            children: [
              GradientRing(
                progress: p.cycleDay / data.cycleLength,
                colors: const [Colors.white, Colors.white70],
                size: 96,
                strokeWidth: 9,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${p.cycleDay}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800)),
                    Text(context.tr('cycle.day'),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${p.phase.emoji} ${context.tr(p.phase.labelKey)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      context.trp('cycle.nextIn', {'n': p.daysUntilNextPeriod}),
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      DateFormat.MMMMd().format(p.nextPeriodStart),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
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
              Text('${p.phase.emoji} ${context.tr(p.phase.labelKey)}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(context.tr(p.phase.tipKey),
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            children: [
              _row(context, '⭐', context.tr('cycle.ovulation'),
                  DateFormat.MMMMd().format(p.ovulationDate)),
              const Divider(),
              _row(
                context,
                p.isFertile ? '🌸' : '🌼',
                context.tr('cycle.fertile'),
                '${DateFormat.MMMd().format(p.fertileStart)} – '
                    '${DateFormat.MMMd().format(p.fertileEnd)}',
                highlight: p.isFertile,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CycleCalendar(data: data),
        const SizedBox(height: 12),
        _NextPeriods(prediction: prediction, cycleLength: data.cycleLength),
        const SizedBox(height: 12),
        const _SymptomSummary(),
        const SizedBox(height: 12),
        const _CycleDiaryCard(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onPeriodStarted,
            icon: const Text('🩸', style: TextStyle(fontSize: 16)),
            label: Text(context.tr('cycle.periodStarted')),
          ),
        ),
        const SizedBox(height: 12),
        Text(context.tr('cycle.disclaimer'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline)),
      ],
    );
  }

  Widget _row(BuildContext context, String emoji, String label, String value,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: highlight ? const Color(0xFFF5576C) : null,
              )),
        ],
      ),
    );
  }
}

/// Setup / edit questionnaire.
class _CycleSetup extends StatefulWidget {
  final CycleData? initial;
  final void Function(CycleData) onSaved;
  const _CycleSetup({required this.onSaved, this.initial});

  @override
  State<_CycleSetup> createState() => _CycleSetupState();
}

class _CycleSetupState extends State<_CycleSetup> {
  late DateTime _lastStart;
  late int _cycleLength;
  late int _periodLength;
  late ProtectionType _protection;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _lastStart = i?.lastPeriodStart ??
        DateTime.now().subtract(const Duration(days: 3));
    _cycleLength = i?.cycleLength ?? 28;
    _periodLength = i?.periodLength ?? 5;
    _protection = i?.protection ?? ProtectionType.pads;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastStart,
      firstDate: now.subtract(const Duration(days: 120)),
      lastDate: now,
    );
    if (picked != null) setState(() => _lastStart = picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      children: [
        Text(context.tr('cycle.setupTitle'),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(context.tr('cycle.setupSub'),
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event),
          title: Text(context.tr('cycle.lastPeriod')),
          trailing: Text(DateFormat.yMMMd().format(_lastStart),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          onTap: _pickDate,
        ),
        const SizedBox(height: 8),
        _stepper(context, context.tr('cycle.cycleLength'), _cycleLength, 21, 40,
            (v) => setState(() => _cycleLength = v),
            unitKey: 'cycle.days'),
        _stepper(context, context.tr('cycle.periodLength'), _periodLength, 2, 10,
            (v) => setState(() => _periodLength = v),
            unitKey: 'cycle.days'),
        const SizedBox(height: 16),
        Text(context.tr('cycle.protectionQ'),
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(context.tr('cycle.protectionSub'),
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in ProtectionType.values)
              ChoiceChip(
                avatar: Text(p.emoji),
                label: Text(context.tr(p.labelKey)),
                selected: _protection == p,
                onSelected: (_) => setState(() => _protection = p),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => widget.onSaved(CycleData(
              lastPeriodStart: _lastStart,
              cycleLength: _cycleLength,
              periodLength: _periodLength,
              protection: _protection,
            )),
            child: Text(context.tr('common.save')),
          ),
        ),
      ],
    );
  }

  Widget _stepper(BuildContext context, String label, int value, int min,
      int max, ValueChanged<int> onChanged,
      {required String unitKey}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton.filledTonal(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 64,
            child: Text('$value ${context.tr(unitKey)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          IconButton.filledTonal(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

/// Today's cycle diary: log bleeding intensity, symptoms and a note (drip-style).
class _CycleDiaryCard extends ConsumerWidget {
  const _CycleDiaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayCycleLogProvider);
    final hasData = today != null && !today.isEmpty;
    return SectionCard(
      onTap: () => _openSheet(context, ref, today),
      child: Row(
        children: [
          const Text('📝', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('diary.title'),
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  hasData ? _summary(context, today) : context.tr('diary.empty'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
          Icon(hasData ? Icons.edit : Icons.add),
        ],
      ),
    );
  }

  String _summary(BuildContext context, CycleDayLog log) {
    final parts = <String>[
      if (log.flow > 0)
        '${log.flowLevel.emoji} ${context.tr(log.flowLevel.labelKey)}',
      for (final id in log.symptoms.take(3))
        if (Symptoms.byId(id) case final s?) context.tr(s.labelKey),
    ];
    return parts.isEmpty ? context.tr('diary.empty') : parts.join(' · ');
  }

  Future<void> _openSheet(
      BuildContext context, WidgetRef ref, CycleDayLog? current) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DiarySheet(
        initial: current,
        onSave: (entry) => ref.read(cycleLogProvider.notifier).log(entry),
      ),
    );
  }
}

class _DiarySheet extends StatefulWidget {
  final CycleDayLog? initial;
  final void Function(CycleDayLog) onSave;
  const _DiarySheet({required this.onSave, this.initial});

  @override
  State<_DiarySheet> createState() => _DiarySheetState();
}

class _DiarySheetState extends State<_DiarySheet> {
  late int _flow;
  late Set<String> _symptoms;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _flow = widget.initial?.flow ?? 0;
    _symptoms = {...?widget.initial?.symptoms};
    _note = TextEditingController(text: widget.initial?.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('diary.title'),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(context.tr('diary.flow'),
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final f in FlowLevel.values)
                  ChoiceChip(
                    label: Text(f == FlowLevel.none
                        ? context.tr(f.labelKey)
                        : '${f.emoji} ${context.tr(f.labelKey)}'),
                    selected: _flow == f.index,
                    onSelected: (_) => setState(() => _flow = f.index),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(context.tr('diary.symptoms'),
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in Symptoms.all)
                  FilterChip(
                    avatar: Text(s.emoji),
                    label: Text(context.tr(s.labelKey)),
                    selected: _symptoms.contains(s.id),
                    onSelected: (v) => setState(() =>
                        v ? _symptoms.add(s.id) : _symptoms.remove(s.id)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.tr('mood.note'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.onSave(CycleDayLog(
                    date: DateTime.now(),
                    flow: _flow,
                    symptoms: _symptoms.toList(),
                    note: _note.text.trim(),
                  ));
                  Navigator.of(context).pop();
                },
                child: Text(context.tr('common.save')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A month calendar coloured by cycle phase (period / fertile / ovulation).
class _CycleCalendar extends StatelessWidget {
  final CycleData data;
  const _CycleCalendar({required this.data});

  @override
  Widget build(BuildContext context) {
    const predictor = CyclePredictor();
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leading = DateTime(now.year, now.month, 1).weekday - 1;

    Color colorFor(DateTime day) {
      final p = predictor.predict(data, day);
      if (p.phase == CyclePhase.menstrual) return const Color(0xFFF5576C);
      if (p.phase == CyclePhase.ovulation) return const Color(0xFFF5A623);
      if (p.isFertile) return const Color(0xFF2E9E6B);
      return Colors.transparent;
    }

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('cycle.calendar'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (var i = 0; i < leading; i++) const SizedBox.shrink(),
              for (var d = 1; d <= daysInMonth; d++)
                Builder(builder: (context) {
                  final date = DateTime(now.year, now.month, d);
                  final c = colorFor(date);
                  final isToday = d == now.day;
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c == Colors.transparent
                          ? Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.4)
                          : c.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                      border: isToday
                          ? Border.all(color: Colors.white, width: 1.5)
                          : null,
                    ),
                    child: Text('$d',
                        style: TextStyle(
                            fontSize: 11,
                            color: c == Colors.transparent
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.white)),
                  );
                }),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _legend(context, const Color(0xFFF5576C), 'cycle.legend.period'),
              _legend(context, const Color(0xFF2E9E6B), 'cycle.legend.fertile'),
              _legend(
                  context, const Color(0xFFF5A623), 'cycle.legend.ovulation'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, Color c, String key) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 5),
          Text(context.tr(key), style: Theme.of(context).textTheme.labelSmall),
        ],
      );
}

/// The next three predicted period start dates.
class _NextPeriods extends StatelessWidget {
  final CyclePrediction prediction;
  final int cycleLength;
  const _NextPeriods(
      {required this.prediction, required this.cycleLength});

  @override
  Widget build(BuildContext context) {
    final dates = [
      prediction.nextPeriodStart,
      prediction.nextPeriodStart.add(Duration(days: cycleLength)),
      prediction.nextPeriodStart.add(Duration(days: cycleLength * 2)),
    ];
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('cycle.upcoming'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          for (final d in dates)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Text('🩸', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 10),
                  Text(DateFormat.yMMMMd().format(d)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Most frequent symptoms from the recent diary.
class _SymptomSummary extends ConsumerWidget {
  const _SymptomSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(cycleLogProvider);
    final counts = <String, int>{};
    for (final e in log) {
      for (final s in e.symptoms) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return const SizedBox.shrink();
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('cycle.commonSymptoms'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in top.take(5))
                if (Symptoms.byId(e.key) case final s?)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Text(s.emoji),
                    label: Text('${context.tr(s.labelKey)} · ${e.value}'),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/mind/domain/mood.dart';
import 'package:lifeos/features/mind/presentation/providers/mood_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// A Daylio-style mood journal: rate the day, tag activities, add a note, and
/// see 30-day trends plus which activities correlate with a better mood.
class MoodJournalPage extends ConsumerWidget {
  const MoodJournalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(moodSummaryProvider);
    final log = ref.watch(moodLogProvider);
    final today = ref.watch(todayMoodProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('mood.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.orbs,
        color: const Color(0xFF7F53AC),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (summary != null) _summaryCard(context, summary),
            if (log.length >= 2) ...[
              const SizedBox(height: 12),
              _trendCard(context, log),
            ],
            if (summary != null && summary.correlations.isNotEmpty) ...[
              const SizedBox(height: 12),
              _correlationsCard(context, summary),
            ],
            const SizedBox(height: 12),
            _MoodForm(
              initial: today,
              onSave: (e) => ref.read(moodLogProvider.notifier).log(e),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context, MoodSummary s) {
    return GradientCard(
      colors: LifeGradients.mind,
      child: Row(
        children: [
          Text(moodFace(s.average.round()),
              style: const TextStyle(fontSize: 44)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.trp('mood.avg', {'n': s.average.toStringAsFixed(1)}),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                Text(
                    context.trp('mood.last30',
                        {'n': s.last30.toStringAsFixed(1)}),
                    style: const TextStyle(color: Colors.white70)),
                Text(context.trp('mood.entries', {'n': s.entries}),
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendCard(BuildContext context, List<MoodEntry> log) {
    final last = log.length > 30 ? log.sublist(log.length - 30) : log;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('mood.trend'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final e in last)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Container(
                        height: (e.mood / 5 * 60).clamp(6, 60),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7F53AC),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _correlationsCard(BuildContext context, MoodSummary s) {
    final shown = s.correlations.take(5).toList();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('mood.correlations'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(context.tr('mood.correlationsSub'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  )),
          const SizedBox(height: 8),
          for (final c in shown) _correlationRow(context, c),
        ],
      ),
    );
  }

  Widget _correlationRow(BuildContext context, MoodCorrelation c) {
    final act = MoodActivities.byId(c.activityId);
    final up = c.delta >= 0;
    final color = up ? const Color(0xFF2E9E6B) : const Color(0xFFE5484D);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(act?.emoji ?? '•'),
          const SizedBox(width: 8),
          Expanded(
              child: Text(act == null ? c.activityId : context.tr(act.labelKey))),
          Text('${up ? '+' : ''}${c.delta.toStringAsFixed(1)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MoodForm extends StatefulWidget {
  final MoodEntry? initial;
  final void Function(MoodEntry) onSave;
  const _MoodForm({required this.onSave, this.initial});

  @override
  State<_MoodForm> createState() => _MoodFormState();
}

class _MoodFormState extends State<_MoodForm> {
  late int _mood;
  late Set<String> _activities;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _mood = widget.initial?.mood ?? 4;
    _activities = {...?widget.initial?.activities};
    _note = TextEditingController(text: widget.initial?.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('mood.today'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var m = 1; m <= 5; m++)
                GestureDetector(
                  onTap: () => setState(() => _mood = m),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _mood == m ? 1 : 0.35,
                    child: Text(moodFace(m),
                        style: TextStyle(fontSize: _mood == m ? 40 : 32)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(context.tr('mood.activities'),
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in MoodActivities.all)
                FilterChip(
                  avatar: Text(a.emoji),
                  label: Text(context.tr(a.labelKey)),
                  selected: _activities.contains(a.id),
                  onSelected: (v) => setState(() =>
                      v ? _activities.add(a.id) : _activities.remove(a.id)),
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
                widget.onSave(MoodEntry(
                  date: DateTime.now(),
                  mood: _mood,
                  activities: _activities.toList(),
                  note: _note.text.trim(),
                ));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                      SnackBar(content: Text(context.tr('mood.saved'))));
              },
              child: Text(context.tr('common.save')),
            ),
          ),
        ],
      ),
    );
  }
}

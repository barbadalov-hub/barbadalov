import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/wellness/domain/vitality.dart';
import 'package:lifeos/features/wellness/presentation/providers/wellness_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';
import 'package:lifeos/shared/widgets/motion.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// The men's analog to cycle tracking: a daily vitality check-in with a
/// wellbeing score, trend, streak and a coached tip.
class VitalityPage extends ConsumerWidget {
  const VitalityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(vitalitySummaryProvider);
    final today = ref.watch(todayCheckinProvider);
    final log = ref.watch(vitalityLogProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('vitality.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.orbs,
        color: const Color(0xFF647DEE),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (summary != null) _summaryCard(context, summary),
            if (summary != null) const SizedBox(height: 12),
            if (log.length >= 2) ...[
              _trendCard(context, log),
              const SizedBox(height: 12),
            ],
            _CheckinForm(
              initial: today,
              onSave: (c) => ref.read(vitalityLogProvider.notifier).log(c),
            ),
            const SizedBox(height: 12),
            Text(context.tr('vitality.disclaimer'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context, VitalitySummary s) {
    return GradientCard(
      colors: LifeGradients.mind,
      child: Row(
        children: [
          GradientRing(
            progress: s.latestScore / 100,
            colors: const [Colors.white, Colors.white70],
            size: 92,
            strokeWidth: 9,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${s.latestScore}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
                const Text('/100',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(s.phaseKey),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('${s.trend.emoji} ${context.tr(s.trend.labelKey)}',
                    style: const TextStyle(color: Colors.white)),
                Text(
                  context.trp('vitality.weekAvg', {'n': s.weekAverage}),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (s.streakDays > 1)
                  Text(context.trp('vitality.streak', {'n': s.streakDays}),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendCard(BuildContext context, List<VitalityCheckin> log) {
    final last = log.length > 14 ? log.sublist(log.length - 14) : log;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('vitality.trendTitle'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final c in last)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Container(
                        height: (c.score / 100 * 66).clamp(3, 66),
                        decoration: BoxDecoration(
                          color: const Color(0xFF647DEE),
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
}

class _CheckinForm extends StatefulWidget {
  final VitalityCheckin? initial;
  final void Function(VitalityCheckin) onSave;
  const _CheckinForm({required this.onSave, this.initial});

  @override
  State<_CheckinForm> createState() => _CheckinFormState();
}

class _CheckinFormState extends State<_CheckinForm> {
  late int _energy;
  late int _mood;
  late int _sleep;
  late int _stress;
  late int _libido;
  late bool _trained;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _energy = i?.energy ?? 3;
    _mood = i?.mood ?? 3;
    _sleep = i?.sleep ?? 3;
    _stress = i?.stress ?? 3;
    _libido = i?.libido ?? 3;
    _trained = i?.trained ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('vitality.checkin'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _slider('⚡', context.tr('vitality.energy'), _energy,
              (v) => setState(() => _energy = v)),
          _slider('🙂', context.tr('vitality.mood'), _mood,
              (v) => setState(() => _mood = v)),
          _slider('😴', context.tr('vitality.sleep'), _sleep,
              (v) => setState(() => _sleep = v)),
          _slider('🔥', context.tr('vitality.stress'), _stress,
              (v) => setState(() => _stress = v)),
          _slider('❤️', context.tr('vitality.libido'), _libido,
              (v) => setState(() => _libido = v)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Text('🏋️', style: TextStyle(fontSize: 20)),
            title: Text(context.tr('vitality.trained')),
            value: _trained,
            onChanged: (v) => setState(() => _trained = v),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onSave(VitalityCheckin(
                  date: DateTime.now(),
                  energy: _energy,
                  mood: _mood,
                  sleep: _sleep,
                  stress: _stress,
                  libido: _libido,
                  trained: _trained,
                ));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                      content: Text(context.tr('vitality.saved'))));
              },
              child: Text(context.tr('common.save')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slider(
      String emoji, String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 116,
            child: Row(
              children: [
                Text(emoji),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(label,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$value',
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          SizedBox(
              width: 18,
              child: Text('$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

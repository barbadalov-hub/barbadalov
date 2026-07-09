import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/health/domain/entities/workout.dart';
import 'package:lifeos/features/health/domain/entities/workout_program.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

class _LoggedSet {
  final double weight;
  final int reps;
  const _LoggedSet(this.weight, this.reps);
}

/// wger-style "Gym Mode": walk through a program's exercises, log each set's
/// weight × reps in one tap, and get a rest timer between sets. Plugin-free
/// (an in-app countdown); last weight per exercise is remembered for next time.
class GymSessionPage extends ConsumerStatefulWidget {
  final WorkoutProgram program;
  const GymSessionPage({required this.program, super.key});

  @override
  ConsumerState<GymSessionPage> createState() => _GymSessionPageState();
}

class _GymSessionPageState extends ConsumerState<GymSessionPage> {
  late final List<Workout> _exercises = widget.program.exercises;
  int _index = 0;
  final Map<int, List<_LoggedSet>> _log = {};
  final _weight = TextEditingController();
  final _reps = TextEditingController();

  int _restRemaining = 0;
  int _restLength = 90;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _prefillWeight();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  Workout get _current => _exercises[_index];
  List<_LoggedSet> get _sets => _log[_index] ??= [];

  String _weightKey(String exId) => 'gym.weight.$exId';

  void _prefillWeight() {
    final saved =
        ref.read(keyValueStoreProvider).getString(_weightKey(_current.id));
    _weight.text = saved ?? '';
    _reps.text = '';
  }

  void _addSet() {
    final w = double.tryParse(_weight.text.replaceAll(',', '.')) ?? 0;
    final r = int.tryParse(_reps.text) ?? 0;
    if (r <= 0) return;
    setState(() => _sets.add(_LoggedSet(w, r)));
    if (w > 0) {
      ref
          .read(keyValueStoreProvider)
          .setString(_weightKey(_current.id), _weight.text.trim());
    }
    _reps.clear();
    _startRest();
  }

  void _startRest() {
    _timer?.cancel();
    setState(() => _restRemaining = _restLength);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _restRemaining--);
      if (_restRemaining <= 0) {
        t.cancel();
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _skipRest() {
    _timer?.cancel();
    setState(() => _restRemaining = 0);
  }

  void _changeRest(int delta) =>
      setState(() => _restLength = (_restLength + delta).clamp(15, 300));

  void _prev() {
    if (_index == 0) return;
    setState(() => _index--);
    _prefillWeight();
    _skipRest();
  }

  void _next() {
    if (_index >= _exercises.length - 1) {
      _finish();
      return;
    }
    setState(() => _index++);
    _prefillWeight();
    _skipRest();
  }

  void _finish() {
    ref
        .read(logHealthProvider)
        .completeWorkout('gym-${widget.program.id}');
    final totalSets = _log.values.fold(0, (s, l) => s + l.length);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(context.trp('gym.finished', {'n': totalSets}))));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_exercises.isEmpty) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final resting = _restRemaining > 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('gym.title')),
        actions: [
          TextButton(
            onPressed: _finish,
            child: Text(context.tr('gym.finish')),
          ),
        ],
      ),
      body: AnimatedBackdrop(
        style: BackdropStyle.pulse,
        color: LifeColors.health,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              context.trp('gym.progress',
                  {'i': _index + 1, 'n': _exercises.length}),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            Text('${_current.emoji}  ${context.tr(_current.nameKey)}',
                style: Theme.of(context).textTheme.headlineSmall),
            Text(
              '${context.tr(_current.musclesKey)} · '
              '${context.tr('gym.target')} ${_current.setsReps}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 14),
            if (resting) _restCard(context) else _inputCard(context),
            const SizedBox(height: 14),
            _setsCard(context),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_index > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _prev,
                      icon: const Icon(Icons.chevron_left),
                      label: Text(context.tr('gym.prev')),
                    ),
                  ),
                if (_index > 0) const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _next,
                    icon: Icon(_index >= _exercises.length - 1
                        ? Icons.check
                        : Icons.chevron_right),
                    label: Text(_index >= _exercises.length - 1
                        ? context.tr('gym.finish')
                        : context.tr('gym.next')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputCard(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.trp('gym.setN', {'n': _sets.length + 1}),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weight,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: context.tr('gym.weight'),
                    suffixText: 'kg',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _reps,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: context.tr('gym.reps'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addSet,
              icon: const Icon(Icons.add),
              label: Text(context.tr('gym.logSet')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _restCard(BuildContext context) {
    return SectionCard(
      color: LifeColors.health.withValues(alpha: 0.14),
      child: Column(
        children: [
          Text(context.tr('gym.rest'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('$_restRemaining ${context.tr('gym.sec')}',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: LifeColors.health,
                  )),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: () => _changeRest(-15),
                  icon: const Icon(Icons.remove_circle_outline)),
              Text('${_restLength}s'),
              IconButton(
                  onPressed: () => _changeRest(15),
                  icon: const Icon(Icons.add_circle_outline)),
              const SizedBox(width: 8),
              TextButton(
                  onPressed: _skipRest, child: Text(context.tr('gym.skip'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _setsCard(BuildContext context) {
    if (_sets.isEmpty) {
      return Text(context.tr('gym.noSets'),
          style: Theme.of(context).textTheme.bodySmall);
    }
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _sets.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  CircleAvatar(
                      radius: 12, child: Text('${i + 1}',
                          style: const TextStyle(fontSize: 12))),
                  const SizedBox(width: 12),
                  Text(
                    _sets[i].weight > 0
                        ? '${_fmt(_sets[i].weight)} kg × ${_sets[i].reps}'
                        : context.trp('gym.repsOnly', {'n': _sets[i].reps}),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _sets.removeAt(i)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(double w) => w == w.roundToDouble() ? '${w.round()}' : '$w';
}

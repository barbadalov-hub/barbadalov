import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/health/presentation/pages/measurements_page.dart';
import 'package:lifeos/features/profile/domain/checkup_advisor.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';
import 'package:lifeos/features/profile/domain/fitness_calculator.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/collapsible_section.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// Body & lifestyle questionnaire. Saving recomputes the assessment (BMI, BMR,
/// TDEE, target kcal & macros) shown below the form and drives the dietitian.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _chest;
  late final TextEditingController _waist;
  late final TextEditingController _hips;
  late final TextEditingController _arm;
  late final TextEditingController _neck;
  late Sex _sex;
  late bool _deskJob;
  late int _workouts;
  late FitnessGoal _goal;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _name = TextEditingController(text: p?.name ?? '');
    _age = TextEditingController(text: p == null ? '' : '${p.age}');
    _height = TextEditingController(text: p == null ? '' : _num(p.heightCm));
    _weight = TextEditingController(text: p == null ? '' : _num(p.weightKg));
    _chest = TextEditingController(text: _opt(p?.chestCm));
    _waist = TextEditingController(text: _opt(p?.waistCm));
    _hips = TextEditingController(text: _opt(p?.hipsCm));
    _arm = TextEditingController(text: _opt(p?.armCm));
    _neck = TextEditingController(text: _opt(p?.neckCm));
    _sex = p?.sex ?? Sex.male;
    _deskJob = p?.deskJob ?? true;
    _workouts = p?.workoutsPerWeek ?? 2;
    _goal = p?.goal ?? FitnessGoal.lose;
  }

  static String _num(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : '$v';
  static String _opt(double? v) => v == null ? '' : _num(v);

  @override
  void dispose() {
    for (final c in [
      _name, _age, _height, _weight, _chest, _waist, _hips, _arm, _neck, //
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.'));

  void _save() {
    final age = int.tryParse(_age.text);
    final height = _parse(_height);
    final weight = _parse(_weight);
    if (age == null || age <= 0 || height == null || height <= 0 ||
        weight == null || weight <= 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.tr('profile.invalid'))));
      return;
    }
    ref.read(profileProvider.notifier).save(UserProfile(
          name: _name.text.trim(),
          sex: _sex,
          age: age,
          heightCm: height,
          weightKg: weight,
          chestCm: _parse(_chest),
          waistCm: _parse(_waist),
          hipsCm: _parse(_hips),
          armCm: _parse(_arm),
          neckCm: _parse(_neck),
          deskJob: _deskJob,
          workoutsPerWeek: _workouts,
          goal: _goal,
        ));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.tr('profile.saved'))));
  }

  @override
  Widget build(BuildContext context) {
    final assessment = ref.watch(assessmentProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('profile.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Text('📐', style: TextStyle(fontSize: 24)),
              title: Text(context.tr('meas.title')),
              subtitle: Text(context.tr('meas.moreSub')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const MeasurementsPage()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _field(_name, context.tr('profile.name'), text: true),
          const SizedBox(height: 12),
          SegmentedButton<Sex>(
            segments: [
              ButtonSegment(
                  value: Sex.male, label: Text(context.tr('profile.male'))),
              ButtonSegment(
                  value: Sex.female, label: Text(context.tr('profile.female'))),
            ],
            selected: {_sex},
            onSelectionChanged: (s) => setState(() => _sex = s.first),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field(_age, context.tr('profile.age'))),
            const SizedBox(width: 8),
            Expanded(child: _field(_height, context.tr('profile.height'))),
            const SizedBox(width: 8),
            Expanded(child: _field(_weight, context.tr('profile.weight'))),
          ]),
          const SizedBox(height: 8),
          CollapsibleSection(
            title: context.tr('profile.tape'),
            children: [
              Row(children: [
                Expanded(child: _field(_chest, context.tr('profile.chest'))),
                const SizedBox(width: 8),
                Expanded(child: _field(_waist, context.tr('profile.waist'))),
                const SizedBox(width: 8),
                Expanded(child: _field(_hips, context.tr('profile.hips'))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _field(_arm, context.tr('profile.arm'))),
                const SizedBox(width: 8),
                Expanded(child: _field(_neck, context.tr('profile.neck'))),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _deskJob,
            onChanged: (v) => setState(() => _deskJob = v),
            title: Text(context.tr('profile.deskJob')),
            subtitle: Text(context.tr('profile.deskJobHint')),
          ),
          Row(children: [
            Expanded(
              child: Text(
                  '${context.tr('profile.workouts')}: $_workouts')),
            Expanded(
              flex: 2,
              child: Slider(
                value: _workouts.toDouble(),
                max: 7,
                divisions: 7,
                label: '$_workouts',
                onChanged: (v) => setState(() => _workouts = v.round()),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          SegmentedButton<FitnessGoal>(
            segments: [
              ButtonSegment(
                  value: FitnessGoal.lose,
                  label: Text(context.tr('profile.lose'))),
              ButtonSegment(
                  value: FitnessGoal.maintain,
                  label: Text(context.tr('profile.maintain'))),
              ButtonSegment(
                  value: FitnessGoal.gain,
                  label: Text(context.tr('profile.gain'))),
            ],
            selected: {_goal},
            onSelectionChanged: (s) => setState(() => _goal = s.first),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(context.tr('profile.save')),
          ),
          const SizedBox(height: 20),
          if (assessment != null) ...[
            _BmiGauge(a: assessment),
            const SizedBox(height: 12),
            _MacroBar(a: assessment),
            const SizedBox(height: 12),
            _IdealWeightCard(
                a: assessment,
                current: ref.watch(profileProvider)?.weightKg ?? 0),
            const SizedBox(height: 12),
            _AssessmentCard(a: assessment),
            const SizedBox(height: 12),
            _CheckupCard(
                profile: ref.watch(profileProvider)!, a: assessment),
          ],
        ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool text = false}) {
    return TextField(
      controller: c,
      keyboardType: text
          ? TextInputType.text
          : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

/// A BMI gauge: coloured bands (under/normal/over/obese) with a marker.
class _BmiGauge extends StatelessWidget {
  final FitnessAssessment a;
  const _BmiGauge({required this.a});

  @override
  Widget build(BuildContext context) {
    // Range 15–40; band widths proportional.
    final pos = ((a.bmi.clamp(15, 40) - 15) / 25).toDouble();
    const bands = [
      (3.5, Color(0xFF3BA7FF)), // <18.5 under
      (6.5, Color(0xFF2E9E6B)), // 18.5–25 normal
      (5.0, Color(0xFFF5A623)), // 25–30 over
      (10.0, Color(0xFFE5484D)), // 30+ obese
    ];
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('profile.bmi'),
                  style: Theme.of(context).textTheme.titleMedium),
              Text('${a.bmi.toStringAsFixed(1)} · ${context.tr(a.bmiKey)}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 20,
            child: Stack(
              children: [
                Row(
                  children: [
                    for (final (w, c) in bands)
                      Expanded(
                        flex: (w * 10).round(),
                        child: Container(color: c),
                      ),
                  ],
                ),
                Align(
                  alignment: Alignment(-1 + 2 * pos, 0),
                  child: Container(
                    width: 4,
                    height: 20,
                    color: Colors.white,
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

/// A stacked macro bar: protein / fat / carbs by grams.
class _MacroBar extends StatelessWidget {
  final FitnessAssessment a;
  const _MacroBar({required this.a});

  @override
  Widget build(BuildContext context) {
    const p = Color(0xFFE5484D);
    const f = Color(0xFFF5A623);
    const c = Color(0xFF3BA7FF);
    final total = (a.proteinG + a.fatG + a.carbsG).clamp(1, 1 << 30);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('profile.macros'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(flex: a.proteinG, child: Container(color: p)),
                  Expanded(flex: a.fatG, child: Container(color: f)),
                  Expanded(flex: a.carbsG, child: Container(color: c)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            children: [
              _legend(context, p, 'profile.protein', a.proteinG, total.toInt()),
              _legend(context, f, 'profile.fat', a.fatG, total.toInt()),
              _legend(context, c, 'profile.carbs', a.carbsG, total.toInt()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, Color color, String key, int g, int total) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text('${context.tr(key)} ${g}g (${(g * 100 / total).round()}%)',
            style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// Current vs ideal weight with the delta to go.
class _IdealWeightCard extends StatelessWidget {
  final FitnessAssessment a;
  final double current;
  const _IdealWeightCard({required this.a, required this.current});

  @override
  Widget build(BuildContext context) {
    final delta = current - a.idealWeightKg;
    final atIdeal = delta.abs() < 0.5;
    return SectionCard(
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('profile.idealWeight'),
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${current.toStringAsFixed(1)} → ${a.idealWeightKg.toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            atIdeal
                ? '✅'
                : context.trp('profile.toGo', {
                    'sign': delta > 0 ? '−' : '+',
                    'n': delta.abs().toStringAsFixed(1),
                  }),
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: atIdeal ? const Color(0xFF2E9E6B) : null),
          ),
        ],
      ),
    );
  }
}

/// Suggested doctors + lab tests from the profile — educational prompts to
/// discuss with a real doctor, never a diagnosis.
class _CheckupCard extends ConsumerWidget {
  final UserProfile profile;
  final FitnessAssessment a;
  const _CheckupCard({required this.profile, required this.a});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = suggestCheckups(profile, a);
    final doctors =
        suggestions.where((s) => s.kind == CheckupKind.doctor).toList();
    final labs = suggestions.where((s) => s.kind == CheckupKind.lab).toList();
    final tracker = ref.watch(checkupTrackerProvider);
    final done = suggestions
        .where((s) => tracker[s.trackKey] == CheckupStatus.done)
        .length;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('🩺 ${context.tr('checkup.title')}',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              if (suggestions.isNotEmpty)
                Text(
                    context.trp('checkup.track.progress',
                        {'done': done, 'total': suggestions.length}),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: LifeColors.finance,
                          fontWeight: FontWeight.w700,
                        )),
            ],
          ),
          const SizedBox(height: 4),
          Text(context.tr('checkup.sub'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  )),
          const SizedBox(height: 12),
          if (doctors.isNotEmpty) ...[
            Text(context.tr('checkup.doctors'),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            for (final s in doctors) _row(context, ref, s, tracker[s.trackKey]),
            const SizedBox(height: 8),
          ],
          if (labs.isNotEmpty) ...[
            Text(context.tr('checkup.labs'),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            for (final s in labs) _row(context, ref, s, tracker[s.trackKey]),
          ],
          const SizedBox(height: 8),
          Text(context.tr('checkup.track.hint'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  )),
          const SizedBox(height: 4),
          Text(context.tr('checkup.disclaimer'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  )),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, CheckupSuggestion s,
      CheckupStatus? status) {
    final st = status ?? CheckupStatus.todo;
    final done = st == CheckupStatus.done;
    return InkWell(
      onTap: () =>
          ref.read(checkupTrackerProvider.notifier).cycle(s.trackKey),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusPill(st),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        decoration:
                            done ? TextDecoration.lineThrough : null,
                        color: done
                            ? Theme.of(context).colorScheme.outline
                            : null,
                      ),
                  children: [
                    TextSpan(
                        text: context.tr(s.labelKey),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    TextSpan(
                        text: ' — ${context.tr(s.reasonKey)}',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable status chip: to-do (outline circle), planned (amber clock),
/// done (green check).
class _StatusPill extends StatelessWidget {
  final CheckupStatus status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color color;
    switch (status) {
      case CheckupStatus.todo:
        icon = Icons.radio_button_unchecked;
        color = Theme.of(context).colorScheme.outline;
      case CheckupStatus.planned:
        icon = Icons.schedule;
        color = const Color(0xFFF5A623);
      case CheckupStatus.done:
        icon = Icons.check_circle;
        color = LifeColors.finance;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  final FitnessAssessment a;
  const _AssessmentCard({required this.a});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('profile.bmi', '${a.bmi.toStringAsFixed(1)} · ${context.tr(a.bmiKey)}'),
      ('profile.bmr', '${a.bmr} ${context.tr('diet.kcal')}'),
      ('profile.tdee', '${a.tdee} ${context.tr('diet.kcal')}'),
      ('profile.targetKcal', '${a.targetKcal} ${context.tr('diet.kcal')}'),
      (
        'profile.macros',
        context.trp('diet.macrosLine',
            {'p': a.proteinG, 'f': a.fatG, 'c': a.carbsG})
      ),
      ('profile.idealWeight', '${a.idealWeightKg.toStringAsFixed(1)} kg'),
      ('profile.water', '${a.waterLiters.toStringAsFixed(1)} l'),
      if (a.whr != null)
        (
          'profile.whr',
          '${a.whr!.toStringAsFixed(2)} · ${context.tr(a.whrHighRisk ? 'profile.whr.high' : 'profile.whr.ok')}'
        ),
      if (a.bodyFatPct != null)
        ('profile.bodyFat', '${a.bodyFatPct!.toStringAsFixed(1)} %'),
    ];
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('profile.assessment'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final (key, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Expanded(child: Text(context.tr(key))),
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
        ],
      ),
    );
  }
}

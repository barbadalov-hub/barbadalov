import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/backup/presentation/providers/local_backup_provider.dart';
import 'package:lifeos/features/home/presentation/providers/today_layout_provider.dart';
import 'package:lifeos/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';

/// First-run welcome: a few cosmos intro slides, then a light setup that seeds
/// the profile so Life-in-Weeks, the dietitian and the Life Score work at once.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  final _name = TextEditingController();
  Sex _sex = Sex.male;
  int _age = 25;
  final Set<String> _focus = {};

  static const _slides = [
    ('🌌', 'onb.1.title', 'onb.1.body'),
    ('🧭', 'onb.2.title', 'onb.2.body'),
    ('📈', 'onb.3.title', 'onb.3.body'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    super.dispose();
  }

  void _finish({bool withProfile = true}) {
    if (withProfile) {
      ref.read(profileProvider.notifier).save(UserProfile(
            name: _name.text.trim(),
            sex: _sex,
            age: _age,
            heightCm: 170,
            weightKg: 70,
          ));
    }
    // Tailor the Today screen to the chosen focus areas.
    if (_focus.isNotEmpty) {
      final layout = focusLayout(_focus);
      ref.read(todayOrderProvider.notifier).setOrder(layout.order);
      ref.read(todayHiddenProvider.notifier).setHidden(layout.hidden);
    }
    ref.read(onboardingDoneProvider.notifier).complete();
  }

  void _restore() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RestoreSheet(
        onRestore: (raw) {
          try {
            ref.read(localBackupProvider).importJson(raw);
            ref.read(onboardingDoneProvider.notifier).complete();
            return true;
          } on FormatException {
            return false;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _slides.length + 1; // focus step index (after setup)
    return Scaffold(
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _restore,
                    icon: const Icon(Icons.restore, size: 18),
                    label: Text(context.tr('onb.restore')),
                  ),
                  TextButton(
                    onPressed: () => _finish(withProfile: false),
                    child: Text(context.tr('onb.skip')),
                  ),
                ],
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    for (final (emoji, title, body) in _slides)
                      _Slide(emoji: emoji, title: title, body: body),
                    _SetupSlide(
                      name: _name,
                      sex: _sex,
                      age: _age,
                      onSex: (s) => setState(() => _sex = s),
                      onAge: (a) => setState(() => _age = a),
                    ),
                    _FocusSlide(
                      selected: _focus,
                      onToggle: (id, on) => setState(
                          () => on ? _focus.add(id) : _focus.remove(id)),
                    ),
                  ],
                ),
              ),
              // Dots.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i <= last; i++)
                    Container(
                      margin: const EdgeInsets.all(4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: i == _page ? 1 : 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (_page < last) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      } else {
                        _finish();
                      }
                    },
                    child: Text(_page < last
                        ? context.tr('onb.next')
                        : context.tr('onb.start')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  const _Slide({required this.emoji, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          Text(context.tr(title),
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(context.tr(body),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _SetupSlide extends StatelessWidget {
  final TextEditingController name;
  final Sex sex;
  final int age;
  final ValueChanged<Sex> onSex;
  final ValueChanged<int> onAge;

  const _SetupSlide({
    required this.name,
    required this.sex,
    required this.age,
    required this.onSex,
    required this.onAge,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          const Text('✨', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(context.tr('onb.setup.title'),
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          TextField(
            controller: name,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: context.tr('profile.name'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<Sex>(
            segments: [
              ButtonSegment(
                  value: Sex.male, label: Text(context.tr('profile.male'))),
              ButtonSegment(
                  value: Sex.female, label: Text(context.tr('profile.female'))),
            ],
            selected: {sex},
            onSelectionChanged: (s) => onSex(s.first),
          ),
          const SizedBox(height: 16),
          Text(context.trp('onb.age', {'n': age})),
          Slider(
            value: age.toDouble(),
            min: 10,
            max: 90,
            divisions: 80,
            label: '$age',
            onChanged: (v) => onAge(v.round()),
          ),
          const SizedBox(height: 8),
          Text(context.tr('onb.setup.hint'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  )),
        ],
      ),
    );
  }
}

/// Final onboarding step: pick focus areas that tailor the Today screen.
class _FocusSlide extends StatelessWidget {
  final Set<String> selected;
  final void Function(String id, bool on) onToggle;

  const _FocusSlide({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          const Text('🎯', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(context.tr('onb.focus.title'),
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(context.tr('onb.focus.hint'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final a in kFocusAreas)
                FilterChip(
                  label: Text('${a.emoji} ${context.tr(a.labelKey)}'),
                  selected: selected.contains(a.id),
                  onSelected: (on) => onToggle(a.id, on),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paste-a-backup sheet shown from the onboarding "Restore" button. [onRestore]
/// returns true on success (the app then swaps to the home screen).
class _RestoreSheet extends StatefulWidget {
  final bool Function(String raw) onRestore;
  const _RestoreSheet({required this.onRestore});

  @override
  State<_RestoreSheet> createState() => _RestoreSheetState();
}

class _RestoreSheetState extends State<_RestoreSheet> {
  final _controller = TextEditingController();
  bool _error = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('onb.restore'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(context.tr('onb.restoreHint'),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 5,
            minLines: 3,
            onChanged: (_) {
              if (_error) setState(() => _error = false);
            },
            decoration: InputDecoration(
              hintText: '{ … }',
              border: const OutlineInputBorder(),
              errorText: _error ? context.tr('onb.restoreFail') : null,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final ok = widget.onRestore(_controller.text.trim());
                if (!ok) setState(() => _error = true);
              },
              icon: const Icon(Icons.restore),
              label: Text(context.tr('onb.restoreDo')),
            ),
          ),
        ],
      ),
    );
  }
}

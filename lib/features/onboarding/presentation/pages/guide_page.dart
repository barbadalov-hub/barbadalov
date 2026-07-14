import 'package:flutter/material.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';

/// Full, re-openable "how to use the app" tutorial. Unlike [OnboardingPage]
/// (a one-time setup wizard), this teaches each area of Lumo and can be opened
/// any time from Today's help button or More → Help. Content is data-driven so
/// adding a step is one row in [_steps] plus three i18n strings.
class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  /// Convenience: push the guide as a full-screen route.
  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const GuidePage()),
      );

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  final _controller = PageController();
  int _page = 0;

  // (emoji, titleKey, bodyKey) — one row per tutorial step.
  static const _steps = <(String, String, String)>[
    ('🌌', 'tour.welcome.t', 'tour.welcome.b'),
    ('📅', 'tour.today.t', 'tour.today.b'),
    ('💰', 'tour.money.t', 'tour.money.b'),
    ('❤️', 'tour.health.t', 'tour.health.b'),
    ('🎯', 'tour.goals.t', 'tour.goals.b'),
    ('🧩', 'tour.more.t', 'tour.more.b'),
    ('🤖', 'tour.ai.t', 'tour.ai.b'),
    ('💾', 'tour.data.t', 'tour.data.b'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _steps.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _steps.length - 1;
    return Scaffold(
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(context.tr('tour.close')),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    for (final (emoji, title, body) in _steps)
                      _GuideSlide(emoji: emoji, title: title, body: body),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _steps.length; i++)
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
                    onPressed: _next,
                    child: Text(
                      last ? context.tr('tour.done') : context.tr('tour.next'),
                    ),
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

class _GuideSlide extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  const _GuideSlide({
    required this.emoji,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Text(emoji, style: const TextStyle(fontSize: 76)),
          const SizedBox(height: 24),
          Text(
            context.tr(title),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Text(
            context.tr(body),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

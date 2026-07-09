import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/coach/domain/coach_engine.dart';
import 'package:lifeos/features/coach/presentation/providers/coach_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';

class _Msg {
  final bool fromCoach;
  final String text;
  const _Msg(this.fromCoach, this.text);
}

/// A rule-based AI life coach you can chat with. It answers from your real data
/// (budget, sleep, mood, streaks, Life Score) — plugin-free, on-device.
class CoachPage extends ConsumerStatefulWidget {
  const CoachPage({super.key});

  @override
  ConsumerState<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends ConsumerState<CoachPage> {
  static const _engine = CoachEngine();
  final _messages = <_Msg>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reply(CoachIntent.greeting);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Adds an optional user bubble then the coach's data-driven answer.
  void _reply(CoachIntent intent, {String? userBubble}) {
    final ctx = ref.read(coachContextProvider);
    final r = _engine.reply(intent, ctx);
    setState(() {
      if (userBubble != null) _messages.add(_Msg(false, userBubble));
      _messages.add(_Msg(true, context.trp(r.messageKey, r.params)));
    });
    _scrollToEnd();
  }

  void _onChip(CoachIntent intent) =>
      _reply(intent, userBubble: context.tr('coach.chip.${intent.name}'));

  void _onSend() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    _reply(_engine.classify(text), userBubble: text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('coach.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _Bubble(msg: _messages[i]),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final s in CoachEngine.suggestions)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(context.tr('coach.chip.${s.name}')),
                        onPressed: () => _onChip(s),
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _onSend(),
                        decoration: InputDecoration(
                          hintText: context.tr('coach.hint'),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.send),
                      onPressed: _onSend,
                    ),
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

class _Bubble extends StatelessWidget {
  final _Msg msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final coach = msg.fromCoach;
    return Align(
      alignment: coach ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: coach
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.75)
              : scheme.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(coach ? 4 : 18),
            bottomRight: Radius.circular(coach ? 18 : 4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (coach) ...[
              const Text('🤖', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                msg.text,
                style: TextStyle(
                  height: 1.35,
                  color: coach ? scheme.onSurface : scheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

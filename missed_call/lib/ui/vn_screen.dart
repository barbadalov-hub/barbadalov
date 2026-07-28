import 'dart:async';

import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../engine/script_act1.dart';
import '../engine/vn_controller.dart';
import 'mood_palette.dart';

/// The visual-novel player: a mood-tinted CG stage on top, a dialogue box
/// below. Tap to advance lines; pick a button at a branch. Horror dead-ends
/// play out as a "death" and loop the night back to 03:14.
///
/// CGs are placeholders (a tinted panel + the art brief) until real anime art
/// is dropped in — the engine and flow are already final.
class VnScreen extends StatefulWidget {
  const VnScreen({super.key});

  @override
  State<VnScreen> createState() => _VnScreenState();
}

class _VnScreenState extends State<VnScreen> {
  late final VnController _controller;
  int _lineIndex = 0;
  bool _safeMode = false;
  bool _reduceMotion = false;
  bool _flash = false;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _controller = VnController(script: actOneScript, startId: kActOneStart);
    _controller.addListener(_onNodeChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
  }

  void _onNodeChanged() {
    setState(() => _lineIndex = 0);
    final VnNode node = _controller.current;
    if (node.isDeath && !_safeMode && !_reduceMotion) {
      setState(() => _flash = true);
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(milliseconds: 220), () {
        if (mounted) {
          setState(() => _flash = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _controller.removeListener(_onNodeChanged);
    _controller.dispose();
    super.dispose();
  }

  VnNode get _node => _controller.current;

  bool get _onLastLine =>
      _node.lines.isEmpty || _lineIndex >= _node.lines.length - 1;

  bool get _showChoices => _onLastLine && _node.choices.isNotEmpty;

  bool get _deathEnd => _onLastLine && _node.isDeath;

  void _onTapStage() {
    if (_showChoices || _deathEnd) {
      return;
    }
    if (!_onLastLine) {
      setState(() => _lineIndex++);
      return;
    }
    _controller.advance();
  }

  @override
  Widget build(BuildContext context) {
    final MoodPalette palette =
        _node.isDeath ? MoodPalette.death : MoodPalette.of(_node.cg.mood);
    return Scaffold(
      body: Stack(
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[palette.bgTop, palette.bgBottom],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: _CgStage(
                      node: _node,
                      palette: palette,
                      onTap: _onTapStage,
                    ),
                  ),
                  _DialogueBox(
                    node: _node,
                    palette: palette,
                    lineIndex: _lineIndex,
                    showChoices: _showChoices,
                    isDeathEnd: _deathEnd,
                    onTapContinue: _onTapStage,
                    onChoose: _controller.choose,
                    onWake: () => _controller.loopFromDeath(_node.id),
                  ),
                ],
              ),
            ),
          ),
          _TopControls(
            palette: palette,
            safeMode: _safeMode,
            loopCount: _controller.loopCount,
            onToggleSafe: () => setState(() => _safeMode = !_safeMode),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _flash ? 0.6 : 0.0,
              duration: const Duration(milliseconds: 120),
              child: const ColoredBox(
                color: Color(0xFFD24A3A),
                child: SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A subtle top row: safe-mode toggle + loop counter.
class _TopControls extends StatelessWidget {
  const _TopControls({
    required this.palette,
    required this.safeMode,
    required this.loopCount,
    required this.onToggleSafe,
  });

  final MoodPalette palette;
  final bool safeMode;
  final int loopCount;
  final VoidCallback onToggleSafe;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 8, 0),
        child: Row(
          children: <Widget>[
            if (loopCount > 0)
              Text(
                'круг ${loopCount + 1}',
                style: TextStyle(
                  color: palette.text.withValues(alpha: 0.5),
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
            const Spacer(),
            TextButton(
              onPressed: onToggleSafe,
              child: Text(
                safeMode ? 'щадящий: вкл' : 'щадящий: выкл',
                style: TextStyle(
                  color: palette.accent.withValues(alpha: 0.8),
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The upper "camera": stands in for the full-screen anime CG.
class _CgStage extends StatelessWidget {
  const _CgStage({
    required this.node,
    required this.palette,
    required this.onTap,
  });

  final VnNode node;
  final MoodPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.35, -0.2),
                radius: 0.9,
                colors: <Color>[
                  palette.accent.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 44, 14, 14),
              child: _Tag(
                node.isDeath ? '✕ ${node.cg.id}' : 'CG · ${node.cg.id}',
                palette,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                node.cg.brief,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.text.withValues(alpha: 0.55),
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The lower dialogue box: speaker label, current line, and choices.
class _DialogueBox extends StatelessWidget {
  const _DialogueBox({
    required this.node,
    required this.palette,
    required this.lineIndex,
    required this.showChoices,
    required this.isDeathEnd,
    required this.onTapContinue,
    required this.onChoose,
    required this.onWake,
  });

  final VnNode node;
  final MoodPalette palette;
  final int lineIndex;
  final bool showChoices;
  final bool isDeathEnd;
  final VoidCallback onTapContinue;
  final void Function(VnChoice) onChoose;
  final VoidCallback onWake;

  @override
  Widget build(BuildContext context) {
    final VnLine? line = node.lines.isEmpty
        ? null
        : node.lines[lineIndex.clamp(0, node.lines.length - 1)];
    final _SpeakerStyle speaker = _SpeakerStyle.of(line?.speaker, palette);

    return GestureDetector(
      onTap: (showChoices || isDeathEnd) ? null : onTapContinue,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 190),
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        decoration: BoxDecoration(
          color: palette.panel.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (speaker.label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  speaker.label,
                  style: TextStyle(
                    color: speaker.color,
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (line != null)
              Text(
                line.text,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 16.5,
                  height: 1.5,
                  fontStyle:
                      speaker.italic ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            if (isDeathEnd) ...<Widget>[
              const SizedBox(height: 14),
              _WakeButton(palette: palette, onTap: onWake),
            ] else if (showChoices) ...<Widget>[
              const SizedBox(height: 14),
              ...node.choices.map((VnChoice c) => _ChoiceButton(
                    choice: c,
                    palette: palette,
                    onTap: () => onChoose(c),
                  )),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'нажми, чтобы продолжить ›',
                  style: TextStyle(
                    color: palette.text.withValues(alpha: 0.4),
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WakeButton extends StatelessWidget {
  const _WakeButton({required this.palette, required this.onTap});

  final MoodPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: palette.accent),
          ),
          child: Text(
            'Проснуться в 03:14  ↻',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.accent,
              fontSize: 14.5,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.choice,
    required this.palette,
    required this.onTap,
  });

  final VnChoice choice;
  final MoodPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool deadly = choice.tag == 'тупик';
    final Color edge = deadly ? const Color(0xFFD24A3A) : palette.accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: edge.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    choice.label,
                    style: TextStyle(color: palette.text, fontSize: 14.5),
                  ),
                ),
                if (choice.tag.isNotEmpty)
                  Text(
                    choice.tag,
                    style: TextStyle(
                      color: edge.withValues(alpha: 0.85),
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.palette);

  final String text;
  final MoodPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: palette.text.withValues(alpha: 0.85),
          fontSize: 9.5,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Maps a [Speaker] to its label + colour + emphasis.
@immutable
class _SpeakerStyle {
  const _SpeakerStyle({
    required this.label,
    required this.color,
    required this.italic,
  });

  final String label;
  final Color color;
  final bool italic;

  static _SpeakerStyle of(Speaker? speaker, MoodPalette palette) {
    switch (speaker) {
      case Speaker.mira:
        return _SpeakerStyle(label: 'М.', color: palette.accent, italic: false);
      case Speaker.you:
        return _SpeakerStyle(label: 'ТЫ', color: palette.accent, italic: false);
      case Speaker.artem:
        return _SpeakerStyle(
            label: 'АРТЁМ', color: palette.accent, italic: false);
      case Speaker.thought:
        return _SpeakerStyle(
          label: 'МЫСЛЬ',
          color: palette.text.withValues(alpha: 0.55),
          italic: true,
        );
      case Speaker.narration:
      case null:
        return const _SpeakerStyle(
            label: '', color: Colors.transparent, italic: true);
    }
  }
}

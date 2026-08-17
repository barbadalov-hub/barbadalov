import 'package:flutter/material.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/speech_gateway.dart';

/// A microphone for any text field.
///
/// Drop it in as a `suffixIcon` and dictation works on the phone. On desktop
/// and web it renders **nothing at all** rather than a button that cannot do
/// anything — an offer the app cannot honour is worse than no offer.
class VoiceInputButton extends StatefulWidget {
  /// The field being dictated into.
  final TextEditingController controller;

  /// Called after the controller changes, for fields that keep derived state
  /// in sync (a live verdict, a validation hint).
  final VoidCallback? onChanged;

  const VoiceInputButton({
    required this.controller,
    this.onChanged,
    super.key,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  bool _listening = false;

  /// What the field held when dictation started. Speech arrives as a growing
  /// transcript rather than as increments, so every update has to replace the
  /// spoken part — while leaving anything typed beforehand untouched. Wiping
  /// what someone already typed would be the rudest possible bug here.
  String _base = '';

  @override
  void dispose() {
    if (_listening) speechGateway.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_listening) {
      await speechGateway.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    _base = widget.controller.text;
    final started = await speechGateway.start(
      // The app's own language: dictating Russian into an English recogniser
      // produces confident nonsense rather than an error.
      localeId: _localeId(context),
      onText: (text) {
        if (!mounted) return;
        final spoken = text.trim();
        final joined = _base.isEmpty
            ? spoken
            : (spoken.isEmpty ? _base : '${_base.trimRight()} $spoken');
        widget.controller
          ..text = joined
          ..selection = TextSelection.collapsed(offset: joined.length);
        widget.onChanged?.call();
      },
      onDone: () {
        if (mounted) setState(() => _listening = false);
      },
    );

    if (!mounted) return;
    if (started) {
      setState(() => _listening = true);
    } else {
      // The most likely reason is a declined microphone, which is a decision
      // rather than a fault — say what happened and leave it alone.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.tr('voice.unavailable'))));
    }
  }

  static String? _localeId(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return switch (code) {
      'ru' => 'ru_RU',
      'uk' => 'uk_UA',
      'en' => 'en_US',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!speechGateway.available) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: context.tr(_listening ? 'voice.stop' : 'voice.dictate'),
      onPressed: _toggle,
      icon: Icon(
        _listening ? Icons.mic : Icons.mic_none,
        color: _listening ? scheme.error : scheme.outline,
      ),
    );
  }
}

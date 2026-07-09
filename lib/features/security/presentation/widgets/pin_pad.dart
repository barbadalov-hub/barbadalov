import 'package:flutter/material.dart';

/// A self-contained numeric PIN entry: title, dots, keypad. Calls [onComplete]
/// with the PIN once [length] digits are entered, then clears itself. The
/// parent shows [error] and can force a reset by changing [resetToken].
class PinPad extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? error;
  final int length;
  final Object? resetToken;
  final void Function(String pin) onComplete;

  const PinPad({
    required this.title,
    required this.onComplete,
    this.subtitle,
    this.error,
    this.length = 4,
    this.resetToken,
    super.key,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _entry = '';

  @override
  void didUpdateWidget(PinPad old) {
    super.didUpdateWidget(old);
    if (old.resetToken != widget.resetToken) _entry = '';
  }

  void _tap(String digit) {
    if (_entry.length >= widget.length) return;
    setState(() => _entry += digit);
    if (_entry.length == widget.length) {
      final pin = _entry;
      widget.onComplete(pin);
      // Clear after the callback so a wrong PIN starts fresh.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _entry = '');
      });
    }
  }

  void _back() {
    if (_entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 6),
          Text(widget.subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _entry.length ? scheme.primary : Colors.transparent,
                  border: Border.all(color: scheme.primary, width: 1.5),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 20,
          child: Text(widget.error ?? '',
              style: TextStyle(color: scheme.error, fontSize: 13)),
        ),
        const SizedBox(height: 8),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final d in row) _key(d)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 76),
            _key('0'),
            _KeyButton(
              onTap: _back,
              child: const Icon(Icons.backspace_outlined),
            ),
          ],
        ),
      ],
    );
  }

  Widget _key(String digit) => _KeyButton(
        onTap: () => _tap(digit),
        child: Text(digit,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
      );
}

class _KeyButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _KeyButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: Center(child: child)),
        ),
      ),
    );
  }
}

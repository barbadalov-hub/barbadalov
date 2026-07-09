import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/security/presentation/providers/security_providers.dart';
import 'package:lifeos/features/security/presentation/widgets/pin_pad.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';

/// Full-screen PIN gate shown while the app is locked.
class LockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlock;
  const LockScreen({required this.onUnlock, super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String? _error;
  int _resetToken = 0;

  void _submit(String pin) {
    if (ref.read(pinEnabledProvider.notifier).verify(pin)) {
      widget.onUnlock();
    } else {
      setState(() {
        _error = context.tr('lock.wrong');
        _resetToken++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 16),
                  PinPad(
                    title: context.tr('lock.title'),
                    subtitle: context.tr('lock.sub'),
                    error: _error,
                    resetToken: _resetToken,
                    onComplete: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

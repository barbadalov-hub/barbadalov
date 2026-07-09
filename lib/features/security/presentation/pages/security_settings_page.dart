import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/security/presentation/providers/security_providers.dart';
import 'package:lifeos/features/security/presentation/widgets/pin_pad.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// Set, change or remove the app-lock PIN.
class SecuritySettingsPage extends ConsumerStatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  ConsumerState<SecuritySettingsPage> createState() =>
      _SecuritySettingsPageState();
}

enum _Flow { menu, verifyCurrent, enterNew, confirmNew }

class _SecuritySettingsPageState extends ConsumerState<SecuritySettingsPage> {
  _Flow _flow = _Flow.menu;
  String _firstEntry = '';
  String? _error;
  int _resetToken = 0;
  bool _disableAfterVerify = false;

  void _reset(_Flow flow) => setState(() {
        _flow = flow;
        _error = null;
        _firstEntry = '';
        _resetToken++;
      });

  void _onVerifyCurrent(String pin) {
    if (!ref.read(pinEnabledProvider.notifier).verify(pin)) {
      setState(() {
        _error = context.tr('lock.wrong');
        _resetToken++;
      });
      return;
    }
    if (_disableAfterVerify) {
      ref.read(pinEnabledProvider.notifier).disable();
      _snack(context.tr('sec.disabled'));
      _reset(_Flow.menu);
    } else {
      _reset(_Flow.enterNew);
    }
  }

  void _onEnterNew(String pin) {
    setState(() {
      _firstEntry = pin;
      _flow = _Flow.confirmNew;
      _error = null;
      _resetToken++;
    });
  }

  void _onConfirmNew(String pin) {
    if (pin != _firstEntry) {
      setState(() {
        _error = context.tr('sec.mismatch');
        _resetToken++;
      });
      return;
    }
    ref.read(pinEnabledProvider.notifier).setPin(pin);
    _snack(context.tr('sec.saved'));
    _reset(_Flow.menu);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(pinEnabledProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('sec.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: _flow == _Flow.menu
            ? _menu(enabled)
            : Center(
                child: SingleChildScrollView(
                  child: PinPad(
                    title: _flowTitle(),
                    error: _error,
                    resetToken: _resetToken,
                    onComplete: _onComplete,
                  ),
                ),
              ),
      ),
    );
  }

  String _flowTitle() => switch (_flow) {
        _Flow.verifyCurrent => context.tr('sec.enterCurrent'),
        _Flow.enterNew => context.tr('sec.enterNew'),
        _Flow.confirmNew => context.tr('sec.confirmNew'),
        _Flow.menu => '',
      };

  void _onComplete(String pin) => switch (_flow) {
        _Flow.verifyCurrent => _onVerifyCurrent(pin),
        _Flow.enterNew => _onEnterNew(pin),
        _Flow.confirmNew => _onConfirmNew(pin),
        _Flow.menu => null,
      };

  Widget _menu(bool enabled) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          child: Row(
            children: [
              Text(enabled ? '🔒' : '🔓', style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  enabled ? context.tr('sec.on') : context.tr('sec.off'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(context.tr('sec.intro'),
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        if (!enabled)
          FilledButton.icon(
            icon: const Icon(Icons.lock_outline),
            label: Text(context.tr('sec.enable')),
            onPressed: () {
              _disableAfterVerify = false;
              _reset(_Flow.enterNew);
            },
          )
        else ...[
          FilledButton.icon(
            icon: const Icon(Icons.password),
            label: Text(context.tr('sec.change')),
            onPressed: () {
              _disableAfterVerify = false;
              _reset(_Flow.verifyCurrent);
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                foregroundColor: LifeColors.financeDanger),
            icon: const Icon(Icons.lock_open),
            label: Text(context.tr('sec.disable')),
            onPressed: () {
              _disableAfterVerify = true;
              _reset(_Flow.verifyCurrent);
            },
          ),
        ],
      ],
    );
  }
}

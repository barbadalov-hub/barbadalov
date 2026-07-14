import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/config/firebase_config.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/google_auth_gateway.dart';
import 'package:lifeos/features/cloud/presentation/providers/cloud_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';

/// First-run gate shown when a cloud project is configured and nobody is
/// signed in yet. Each person registers (or signs in) here, so every account
/// is separate and its data lives under that user in the cloud database.
/// Once [accountEmailProvider] is set, the gate lets the app through.
class AuthGatePage extends ConsumerStatefulWidget {
  const AuthGatePage({super.key});

  @override
  ConsumerState<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends ConsumerState<AuthGatePage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _existing = false; // false = register, true = sign in
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  static String _short(String code) {
    if (code.startsWith('EMAIL_EXISTS')) return 'exists';
    if (code.startsWith('INVALID_LOGIN') ||
        code.startsWith('INVALID_PASSWORD') ||
        code.startsWith('EMAIL_NOT_FOUND')) {
      return 'login';
    }
    if (code.startsWith('WEAK_PASSWORD')) return 'weak';
    if (code.startsWith('NO_CONNECTION')) return 'net';
    return 'generic';
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _password.text;
    if (!email.contains('@') || pass.length < 6) {
      _snack(context.tr('acc.invalid'));
      return;
    }
    setState(() => _busy = true);
    final client = ref.read(firebaseRestClientProvider);
    final err = _existing
        ? await client.signInWithEmail(email, pass)
        : await client.linkEmailPassword(email, pass);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      _password.clear(); // success flips the gate via accountEmailProvider
    } else {
      _snack(context.tr('acc.err.${_short(err)}'));
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _busy = true);
    final token = await googleAuthGateway.getIdToken();
    if (token == null) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(context.tr('acc.googleCancelled'));
      return;
    }
    final err =
        await ref.read(firebaseRestClientProvider).signInWithGoogle(token);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) _snack(context.tr('acc.err.${_short(err)}'));
  }

  @override
  Widget build(BuildContext context) {
    final showGoogle =
        FirebaseConfig.googleClientId.isNotEmpty && googleAuthGateway.available;
    return Scaffold(
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('🌌',
                        style: TextStyle(fontSize: 64),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text(
                      _existing
                          ? context.tr('reg.signinTitle')
                          : context.tr('reg.title'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('reg.subtitle'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enabled: !_busy,
                      decoration: InputDecoration(
                        labelText: context.tr('acc.email'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      enabled: !_busy,
                      onSubmitted: (_) => _busy ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: context.tr('acc.password'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_existing
                              ? context.tr('acc.signIn')
                              : context.tr('reg.create')),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _existing = !_existing),
                      child: Text(_existing
                          ? context.tr('reg.toCreate')
                          : context.tr('reg.toSignin')),
                    ),
                    if (showGoogle) ...[
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _googleSignIn,
                        icon: const Text('G',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16)),
                        label: Text(context.tr('acc.google')),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

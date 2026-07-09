import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/google_auth_gateway.dart';
import 'package:lifeos/features/cloud/presentation/providers/cloud_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// Account screen: link the anonymous device identity to an email (so the same
/// cloud history follows you to other devices), sign in to an existing account,
/// or sign out. Plugin-free — everything goes through [FirebaseRestClient].
class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _existing = false; // false = link/register, true = sign in
  bool _busy = false;
  bool _busyCloud = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

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
      _snack(context.tr('acc.done'));
      _password.clear();
    } else {
      _snack(context.tr('acc.err.${_short(err)}'));
    }
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

  Future<void> _googleSignIn() async {
    setState(() => _busy = true);
    final token = await googleAuthGateway.getIdToken();
    if (token == null) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(context.tr('acc.googleCancelled'));
      return;
    }
    final err = await ref.read(firebaseRestClientProvider).signInWithGoogle(token);
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(err == null
        ? context.tr('acc.done')
        : context.tr('acc.err.${_short(err)}'));
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  static String _fmt(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? iso : DateFormat.yMMMd().add_Hm().format(d.toLocal());
  }

  Future<void> _backup() async {
    setState(() => _busyCloud = true);
    final ok = await ref.read(cloudBackupProvider.notifier).backup();
    if (!mounted) return;
    setState(() => _busyCloud = false);
    _snack(context.tr(ok ? 'acc.backupOk' : 'acc.backupFail'));
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('acc.restore')),
        content: Text(ctx.tr('acc.restoreConfirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr('acc.restore'))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busyCloud = true);
    final ok = await ref.read(cloudBackupProvider.notifier).restore();
    if (!mounted) return;
    setState(() => _busyCloud = false);
    _snack(context.tr(ok ? 'acc.restoreOk' : 'acc.restoreNone'));
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(accountEmailProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('acc.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GradientCard(
              colors: email == null
                  ? const [Color(0xFF515A6E), Color(0xFF2C3446)]
                  : LifeGradients.mind,
              child: Row(
                children: [
                  Text(email == null ? '👤' : '✅',
                      style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          email ?? context.tr('acc.anonymous'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        Text(
                          email == null
                              ? context.tr('acc.anonymousHint')
                              : context.tr('acc.signedIn'),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (email == null) ...[
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _existing
                          ? context.tr('acc.signInTitle')
                          : context.tr('acc.linkTitle'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _existing
                          ? context.tr('acc.signInHint')
                          : context.tr('acc.linkHint'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: context.tr('acc.email'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: context.tr('acc.password'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_existing
                              ? context.tr('acc.signIn')
                              : context.tr('acc.link')),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _existing = !_existing),
                      child: Text(_existing
                          ? context.tr('acc.toLink')
                          : context.tr('acc.toSignIn')),
                    ),
                  ],
                ),
              ),
              if (googleAuthGateway.available) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _googleSignIn,
                    icon: const Text('G',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    label: Text(context.tr('acc.google')),
                  ),
                ),
              ],
            ] else
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                style: OutlinedButton.styleFrom(
                    foregroundColor: LifeColors.financeDanger),
                onPressed: () {
                  ref.read(firebaseRestClientProvider).signOut();
                  _snack(context.tr('acc.signedOut'));
                },
                label: Text(context.tr('acc.signOut')),
              ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('☁️ ${context.tr('acc.backupTitle')}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    ref.watch(cloudBackupProvider) == null
                        ? context.tr('acc.neverBackedUp')
                        : context.trp('acc.lastBackup', {
                            'when': _fmt(ref.watch(cloudBackupProvider)!),
                          }),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _busyCloud ? null : _backup,
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: Text(context.tr('acc.backupNow')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busyCloud ? null : _restore,
                          icon: const Icon(Icons.cloud_download_outlined),
                          label: Text(context.tr('acc.restore')),
                        ),
                      ),
                    ],
                  ),
                  if (_busyCloud)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('acc.note'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

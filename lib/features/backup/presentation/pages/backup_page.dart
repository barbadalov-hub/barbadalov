import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/utils/download_file.dart';
import 'package:lifeos/features/backup/presentation/providers/local_backup_provider.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';

/// Offline, account-free backup. Export copies the whole app state to the
/// clipboard (and downloads a file on web); import restores it from pasted JSON.
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  final _importCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _importCtrl.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final message = context.tr('backup.copied');
    final json = ref.read(localBackupProvider).exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    ref.read(backupStatusProvider.notifier).markExported();
    _toast(message);
  }

  void _download() {
    final json = ref.read(localBackupProvider).exportJson();
    final stamp = DateTime.now().toIso8601String().split('T').first;
    final ok = downloadTextFile('lifeos-backup-$stamp.json', json);
    ref.read(backupStatusProvider.notifier).markExported();
    _toast(ok ? context.tr('backup.downloaded') : context.tr('backup.copyHint'));
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _importCtrl.text = data!.text!;
      setState(() {});
    }
  }

  Future<void> _import() async {
    final raw = _importCtrl.text.trim();
    if (raw.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(ctx.tr('backup.importTitle')),
            content: Text(ctx.tr('backup.importWarn')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(ctx.tr('common.cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(ctx.tr('backup.import')),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    setState(() => _busy = true);
    try {
      final n = ref.read(localBackupProvider).importJson(raw);
      _importCtrl.clear();
      _toast(l10n.trp('backup.imported', {'n': n}));
    } on FormatException {
      _toast(l10n.tr('backup.importError'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(localBackupProvider).entryCount;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('backup.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(context.tr('backup.intro'),
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),

            // --- Export ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📤', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Text(context.tr('backup.exportTitle'),
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.trp('backup.exportSub', {'n': count}),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _copy,
                          icon: const Icon(Icons.copy_all),
                          label: Text(context.tr('backup.copy')),
                        ),
                        OutlinedButton.icon(
                          onPressed: _download,
                          icon: const Icon(Icons.download),
                          label: Text(context.tr('backup.download')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // --- Import ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📥', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Text(context.tr('backup.importTitle'),
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(context.tr('backup.importSub'),
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _importCtrl,
                      minLines: 3,
                      maxLines: 6,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        hintText: '{ "money.transactions": ... }',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pasteFromClipboard,
                          icon: const Icon(Icons.paste),
                          label: Text(context.tr('backup.paste')),
                        ),
                        FilledButton.icon(
                          onPressed: _busy ? null : _import,
                          icon: _busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.restore),
                          label: Text(context.tr('backup.import')),
                        ),
                      ],
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/notifications/domain/entities/app_notification.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_prefs.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

/// Control which notifications fire, and a quiet-hours window.
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);
    final ctrl = ref.read(notificationPrefsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('nprefs.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(context.tr('nprefs.intro'),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            SectionCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final cat in notifCategories)
                    SwitchListTile(
                      secondary:
                          Text(cat.emoji, style: const TextStyle(fontSize: 22)),
                      title: Text(context.tr(cat.labelKey)),
                      value: prefs.enabled(cat.id),
                      onChanged: (v) => ctrl.setCategory(cat.id, v),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary:
                        const Text('🌙', style: TextStyle(fontSize: 22)),
                    title: Text(context.tr('nprefs.quiet')),
                    subtitle: Text(context.tr('nprefs.quietHint')),
                    value: prefs.quietEnabled,
                    onChanged: (v) => ctrl.setQuiet(enabled: v),
                  ),
                  if (prefs.quietEnabled)
                    Row(
                      children: [
                        Expanded(
                          child: _timeTile(context, context.tr('nprefs.from'),
                              prefs.quietStart, (h) => ctrl.setQuiet(start: h)),
                        ),
                        Expanded(
                          child: _timeTile(context, context.tr('nprefs.to'),
                              prefs.quietEnd, (h) => ctrl.setQuiet(end: h)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text(context.tr('nprefs.test')),
              onPressed: () {
                ref.read(notificationRepositoryProvider).add(AppNotification(
                      id: 'test-${DateTime.now().millisecondsSinceEpoch}',
                      tier: NotificationTier.optional,
                      titleKey: 'nprefs.testTitle',
                      bodyKey: 'nprefs.testBody',
                      createdAt: ref.read(clockProvider).now(),
                    ));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                      SnackBar(content: Text(context.tr('nprefs.testSent'))));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeTile(
      BuildContext context, String label, int hour, ValueChanged<int> onSet) {
    return ListTile(
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text('${hour.toString().padLeft(2, '0')}:00',
          style: Theme.of(context).textTheme.titleMedium),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: 0),
        );
        if (picked != null) onSet(picked.hour);
      },
    );
  }
}

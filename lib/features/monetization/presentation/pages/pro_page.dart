import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/monetization/presentation/providers/pro_providers.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

class ProPage extends ConsumerWidget {
  const ProPage({super.key});

  static const _featureKeys = [
    'pro.feature.ai',
    'pro.feature.predictions',
    'pro.feature.analytics',
    'pro.feature.integrations',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('pro.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            color: isPro ? scheme.primaryContainer : scheme.surfaceContainerHighest,
            child: Row(
              children: [
                Text(isPro ? '⭐' : '🔓', style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPro ? context.tr('pro.active') : context.tr('pro.free'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(context.tr('pro.blurb'),
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final key in _featureKeys)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.check_circle,
                  color: isPro ? scheme.primary : scheme.outline),
              title: Text(context.tr(key)),
            ),
          const SizedBox(height: 16),
          if (!isPro)
            FilledButton.icon(
              onPressed: () => ref.read(isProProvider.notifier).setPro(true),
              icon: const Icon(Icons.star),
              label: Text(context.tr('pro.upgrade')),
            )
          else
            OutlinedButton(
              onPressed: () => ref.read(isProProvider.notifier).setPro(false),
              child: Text(context.tr('pro.manage')),
            ),
          const SizedBox(height: 8),
          Text(context.tr('pro.demoNote'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.outline,
                  )),
        ],
      ),
    );
  }
}

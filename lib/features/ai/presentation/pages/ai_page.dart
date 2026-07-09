import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/ai/domain/ai_insight.dart';
import 'package:lifeos/features/ai/presentation/providers/ai_providers.dart';
import 'package:lifeos/features/monetization/presentation/pages/pro_page.dart';
import 'package:lifeos/features/monetization/presentation/providers/pro_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

class AiPage extends ConsumerWidget {
  const AiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(aiInsightsProvider);
    final isPro = ref.watch(isProProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('ai.title'))),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: !isPro
          ? const _ProLock()
          : insights.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) return const _AiEmpty();
          final focus = list.first;
          final rest = list.skip(1).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Focus of the day — the single most important thing.
              GradientCard(
                colors: LifeGradients.mind,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🤖', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(context.tr('ai.focus'),
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${focus.emoji} ${context.tr(focus.titleKey)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(context.trp(focus.messageKey, focus.params),
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              if (rest.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(context.trp('ai.more', {'n': rest.length}),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final insight in rest) ...[
                  _InsightCard(insight: insight),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          );
        },
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final AiInsight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(insight.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(insight.titleKey),
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(context.trp(insight.messageKey, insight.params)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the engine has no pressing insights — a good thing.
class _AiEmpty extends StatelessWidget {
  const _AiEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✨', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(context.tr('ai.allClear'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(context.tr('ai.allClearHint'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Shown on the AI screen when the user is on the Free plan (spec §20).
class _ProLock extends StatelessWidget {
  const _ProLock();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(context.tr('ai.locked'),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(context.tr('ai.lockedHint'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProPage()),
              ),
              icon: const Icon(Icons.star),
              label: Text(context.tr('pro.upgrade')),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/notifications/domain/entities/app_notification.dart';
import 'package:lifeos/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('notif.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: context.tr('nprefs.title'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const NotificationSettingsPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: context.tr('notif.clearAll'),
            onPressed: () => _confirmClear(context, ref),
          ),
          TextButton(
            onPressed: () =>
                ref.read(notificationRepositoryProvider).markAllRead(),
            child: Text(context.tr('notif.markAllRead')),
          ),
        ],
      ),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: feed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (all) {
            if (all.isEmpty) return const _EmptyState();
            final unreadOnly = ref.watch(notifUnreadOnlyProvider);
            final tier = ref.watch(notifFilterProvider);
            final items = [
              for (final n in all)
                if ((!unreadOnly || !n.read) && (tier == null || n.tier == tier))
                  n,
            ];
            return Column(
              children: [
                const _FilterBar(),
                Expanded(
                  child: items.isEmpty
                      ? Center(child: Text(context.tr('notif.noMatch')))
                      : ListView(
                          padding: const EdgeInsets.all(12),
                          children: _grouped(context, ref, items),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('notif.clearAll')),
        content: Text(ctx.tr('notif.clearConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('notif.clearAll')),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(notificationRepositoryProvider).clear();
  }

  /// Groups the feed under day headers (Today / Yesterday / date).
  List<Widget> _grouped(
      BuildContext context, WidgetRef ref, List<AppNotification> items) {
    final now = DateTime.now();
    String label(DateTime d) {
      final day = DateTime(d.year, d.month, d.day);
      final today = DateTime(now.year, now.month, now.day);
      final diff = today.difference(day).inDays;
      if (diff == 0) return context.tr('notif.today');
      if (diff == 1) return context.tr('notif.yesterday');
      return DateFormat.yMMMd().format(d);
    }

    final out = <Widget>[];
    String? current;
    for (final n in items) {
      final l = label(n.createdAt);
      if (l != current) {
        current = l;
        out.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
          child: Text(l,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
        ));
      }
      out.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Dismissible(
          key: ValueKey(n.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) =>
              ref.read(notificationRepositoryProvider).remove(n.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFE5484D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: _NotificationTile(item: n),
        ),
      ));
    }
    return out;
  }
}

/// Filter chips: unread toggle + per-tier.
class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadOnly = ref.watch(notifUnreadOnlyProvider);
    final tier = ref.watch(notifFilterProvider);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(context.tr('notif.unreadOnly')),
              selected: unreadOnly,
              onSelected: (v) =>
                  ref.read(notifUnreadOnlyProvider.notifier).state = v,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(context.tr('notif.all')),
              selected: tier == null,
              onSelected: (_) =>
                  ref.read(notifFilterProvider.notifier).state = null,
            ),
          ),
          for (final t in NotificationTier.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_tierMeta(t).emoji),
                selected: tier == t,
                onSelected: (_) =>
                    ref.read(notifFilterProvider.notifier).state = t,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔔', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(context.tr('notif.empty'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(context.tr('notif.emptyHint'),
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;
  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final meta = _tierMeta(item.tier);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: meta.color.withValues(alpha: 0.15),
          child: Text(meta.emoji),
        ),
        title: Text(context.tr(item.titleKey),
            style: TextStyle(
                fontWeight: item.read ? FontWeight.normal : FontWeight.bold)),
        subtitle: Text(context.trp(item.bodyKey, item.params)),
        trailing: Text(
          DateFormat.Hm().format(item.createdAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _TierMeta {
  final String emoji;
  final Color color;
  const _TierMeta(this.emoji, this.color);
}

_TierMeta _tierMeta(NotificationTier tier) => switch (tier) {
      NotificationTier.critical => const _TierMeta('🔴', Color(0xFFE5484D)),
      NotificationTier.important => const _TierMeta('🟡', Color(0xFFF5A623)),
      NotificationTier.optional => const _TierMeta('🟢', Color(0xFF2E9E6B)),
      NotificationTier.aiInsight => const _TierMeta('🤖', Color(0xFF8E5BFF)),
    };

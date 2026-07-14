import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/reminders/domain/entities/reminder.dart';
import 'package:lifeos/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';

class RemindersPage extends ConsumerWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);
    final suggestions = ref.watch(reminderSuggestionsProvider);
    final active = reminders.where((r) => r.enabled).length;
    final sorted = [...reminders]..sort((a, b) =>
        (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('reminder.title')),
        actions: [
          if (reminders.isNotEmpty)
            IconButton(
              tooltip: active > 0
                  ? context.tr('reminder.disableAll')
                  : context.tr('reminder.enableAll'),
              icon: Icon(active > 0
                  ? Icons.notifications_off_outlined
                  : Icons.notifications_active_outlined),
              onPressed: () => ref
                  .read(remindersProvider.notifier)
                  .setAllEnabled(active == 0),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-reminders',
        onPressed: () => _addReminder(context, ref),
        icon: const Icon(Icons.add_alert),
        label: Text(context.tr('reminder.add')),
      ),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: const Color(0xFF7B5CFF),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          children: [
            Card(
              color: Colors.white.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Text('🔔', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('reminder.intro'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (reminders.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SummaryCard(active: active, next: _nextUp(sorted)),
            ],
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SuggestionsCard(
                kinds: suggestions,
                onAdd: (k) => _quickAdd(ref, k),
              ),
            ],
            const SizedBox(height: 12),
            if (reminders.isEmpty)
              _EmptyState(onQuickAdd: (k) => _quickAdd(ref, k))
            else
              ...sorted.map(
                (r) => _ReminderTile(
                  reminder: r,
                  onToggle: () =>
                      ref.read(remindersProvider.notifier).toggle(r.id),
                  onDelete: () =>
                      ref.read(remindersProvider.notifier).remove(r.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _quickAdd(WidgetRef ref, ReminderKind kind) {
    ref.read(remindersProvider.notifier).add(
          kind: kind,
          hour: kind.defaultHour,
          minute: kind.defaultMinute,
        );
  }

  /// The soonest enabled reminder from now (wrapping to tomorrow's earliest).
  Reminder? _nextUp(List<Reminder> sortedByTime) {
    final enabled = sortedByTime.where((r) => r.enabled).toList();
    if (enabled.isEmpty) return null;
    final now = DateTime.now();
    final mins = now.hour * 60 + now.minute;
    for (final r in enabled) {
      if (r.hour * 60 + r.minute >= mins) return r;
    }
    return enabled.first;
  }

  Future<void> _addReminder(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AddReminderSheet(
        onCreate: (kind, label, hour, minute) => ref
            .read(remindersProvider.notifier)
            .add(kind: kind, customLabel: label, hour: hour, minute: minute),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ReminderTile({
    required this.reminder,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final label = reminder.kind == ReminderKind.custom
        ? (reminder.customLabel.isEmpty
            ? context.tr('reminder.kind.custom')
            : reminder.customLabel)
        : context.tr(reminder.kind.labelKey);
    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFE5484D),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        child: ListTile(
          leading: Text(reminder.kind.emoji,
              style: const TextStyle(fontSize: 26)),
          title: Text(label),
          subtitle: Text(reminder.timeLabel),
          trailing: Switch(value: reminder.enabled, onChanged: (_) => onToggle()),
        ),
      ),
    );
  }
}

/// Data-driven suggestions: reminders LifeOS thinks would help, one tap to add.
class _SuggestionsCard extends StatelessWidget {
  final List<ReminderKind> kinds;
  final void Function(ReminderKind) onAdd;
  const _SuggestionsCard({required this.kinds, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 4),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(context.tr('reminder.suggested'),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            for (final k in kinds)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Text(k.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(context.tr(k.labelKey)),
                subtitle: Text(context.tr('reminder.why.${k.name}')),
                trailing: TextButton.icon(
                  onPressed: () => onAdd(k),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(context.tr('common.add')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Active count + the next reminder coming up.
class _SummaryCard extends StatelessWidget {
  final int active;
  final Reminder? next;
  const _SummaryCard({required this.active, required this.next});

  @override
  Widget build(BuildContext context) {
    final label = next == null
        ? null
        : (next!.kind == ReminderKind.custom
            ? (next!.customLabel.isEmpty
                ? context.tr('reminder.kind.custom')
                : next!.customLabel)
            : context.tr(next!.kind.labelKey));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Text('⏰', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.trp('reminder.activeCount', {'n': active}),
                      style: Theme.of(context).textTheme.titleMedium),
                  if (next != null)
                    Text(
                      context.trp('reminder.nextUp', {
                        'emoji': next!.kind.emoji,
                        'label': label ?? '',
                        'time': next!.timeLabel,
                      }),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final void Function(ReminderKind) onQuickAdd;
  const _EmptyState({required this.onQuickAdd});

  static const _suggested = [
    ReminderKind.water,
    ReminderKind.workout,
    ReminderKind.sleep,
    ReminderKind.checkin,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text('⏰', style: TextStyle(fontSize: 44)),
        const SizedBox(height: 8),
        Text(context.tr('reminder.empty'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(context.tr('reminder.emptyHint'),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final k in _suggested)
              ActionChip(
                avatar: Text(k.emoji),
                label: Text(context.tr(k.labelKey)),
                onPressed: () => onQuickAdd(k),
              ),
          ],
        ),
      ],
    );
  }
}

/// Bottom sheet to configure a new reminder: pick a kind (or custom text) and a
/// time of day.
class _AddReminderSheet extends StatefulWidget {
  final void Function(ReminderKind kind, String label, int hour, int minute)
      onCreate;
  const _AddReminderSheet({required this.onCreate});

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  ReminderKind _kind = ReminderKind.water;
  final _customCtrl = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    _time = TimeOfDay(hour: _kind.defaultHour, minute: _kind.defaultMinute);
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _selectKind(ReminderKind k) {
    setState(() {
      _kind = k;
      if (k != ReminderKind.custom) {
        _time = TimeOfDay(hour: k.defaultHour, minute: k.defaultMinute);
      }
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('reminder.add'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in ReminderKind.values)
                ChoiceChip(
                  avatar: Text(k.emoji),
                  label: Text(context.tr(k.labelKey)),
                  selected: _kind == k,
                  onSelected: (_) => _selectKind(k),
                ),
            ],
          ),
          if (_kind == ReminderKind.custom) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customCtrl,
              decoration: InputDecoration(
                labelText: context.tr('reminder.customLabel'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(context.tr('reminder.time')),
            trailing: Text(
              _time.format(context),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: _pickTime,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onCreate(
                    _kind, _customCtrl.text.trim(), _time.hour, _time.minute);
                Navigator.of(context).pop();
              },
              child: Text(context.tr('common.add')),
            ),
          ),
        ],
      ),
    );
  }
}

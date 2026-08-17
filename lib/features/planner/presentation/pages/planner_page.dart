import 'package:flutter/material.dart';
import 'package:lifeos/shared/widgets/voice_input_button.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/notification_gateway.dart';
import 'package:lifeos/features/mind/domain/entities/day_task.dart';
import 'package:lifeos/features/mind/presentation/providers/mind_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';

/// The day as one rail of time: what already happened above the "now" line,
/// what is planned below it. Same tasks as the Mind room — this is the view
/// that gives them an hour and, if asked, a nudge.
class PlannerPage extends ConsumerWidget {
  const PlannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider).valueOrNull ?? const <DayTask>[];
    final now = ref.watch(clockProvider).now();
    final lang = Localizations.localeOf(context).languageCode;
    final nowMinutes = now.hour * 60 + now.minute;

    final timed = [...tasks.where((t) => t.isTimed)]
      ..sort((a, b) => a.atMinutes!.compareTo(b.atMinutes!));
    final untimed = tasks.where((t) => !t.isTimed).toList();
    final done = tasks.where((t) => t.done).length;

    var date = DateFormat.MMMMEEEEd(lang).format(now);
    if (date.isNotEmpty) date = date[0].toUpperCase() + date.substring(1);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('planner.title'))),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-planner',
        onPressed: () => _addDialog(context, ref, now),
        icon: const Icon(Icons.add),
        label: Text(context.tr('planner.add')),
      ),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: LifeColors.info,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            // Both sides must flex: a spelled-out Russian date plus the counter
            // overflows a phone width otherwise.
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    date,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (tasks.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      context.trp('planner.progress',
                          {'done': done, 'total': tasks.length}),
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            if (tasks.isEmpty) ...[
              Text(context.tr('planner.empty'),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.outline)),
              const SizedBox(height: 10),
            ],
            // The hours are always drawn, full or not. A day planner showing
            // nothing but a message is a blank page: the shape of the day is
            // the whole point, and an empty hour you can tap is an invitation
            // where a void is a dead end.
            for (final hour in _railHours(timed))
              _HourBlock(
                hour: hour,
                tasks: [
                  for (final t in timed)
                    if (t.hour == hour) t,
                ],
                nowMinutes: nowMinutes,
                onToggle: (t) => ref.read(toggleTaskProvider).call(t),
                onAdd: () => _addDialog(context, ref, now, atHour: hour),
              ),
            if (untimed.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(context.tr('planner.anytime'),
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final t in untimed)
                _RailRow(
                  task: t,
                  past: false,
                  onToggle: () => ref.read(toggleTaskProvider).call(t),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addDialog(
    BuildContext context,
    WidgetRef ref,
    DateTime now, {
    /// Set when the user tapped an empty hour on the rail, so the dialog opens
    /// already pointing at the slot they chose.
    int? atHour,
  }) async {
    final controller = TextEditingController();
    TimeOfDay? time = TimeOfDay(hour: atHour ?? now.hour, minute: 0);
    var notify = true;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(ctx.tr('planner.add')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration:
                    InputDecoration(
                  labelText: ctx.tr('planner.what'),
                  suffixIcon: VoiceInputButton(controller: controller),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(time == null
                    ? ctx.tr('planner.anytime')
                    : time!.format(ctx)),
                trailing: time == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: ctx.tr('planner.clearTime'),
                        onPressed: () => setState(() {
                          time = null;
                          notify = false;
                        }),
                      ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: time ?? TimeOfDay(hour: now.hour, minute: 0),
                  );
                  if (picked != null) setState(() => time = picked);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.notifications_none),
                title: Text(ctx.tr('planner.notify')),
                // A bell without a time would never ring.
                value: notify && time != null,
                onChanged: time == null
                    ? null
                    : (v) => setState(() => notify = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('common.cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr('common.add')),
            ),
          ],
        ),
      ),
    );

    if (created != true || controller.text.trim().isEmpty) return;
    final at = time == null ? null : time!.hour * 60 + time!.minute;
    final result = ref.read(addTaskProvider).call(
          controller.text,
          atMinutes: at,
          notify: notify,
        );

    // Schedule the one-off nudge for the task we just created.
    final task = result.valueOrNull;
    if (task != null && task.notify && task.atMinutes != null) {
      await notificationGateway.scheduleAt(
        id: task.notificationId,
        title: context.mounted ? context.tr('planner.pushTitle') : task.title,
        body: task.title,
        when: DateTime(now.year, now.month, now.day)
            .add(Duration(minutes: task.atMinutes!)),
      );
    }
  }
}

/// One stop on the day's rail: the time, a state dot, the task, a bell.
/// Which hours the rail draws.
///
/// A waking day by default, widened to cover anything scheduled outside it —
/// a 6am run or a task at midnight must not fall off the rail.
List<int> _railHours(List<DayTask> timed) {
  var from = 7;
  var to = 22;
  for (final t in timed) {
    final h = t.hour;
    if (h == null) continue;
    if (h < from) from = h;
    if (h > to) to = h;
  }
  return [for (var h = from; h <= to; h++) h];
}

/// One hour of the day: what is planned in it, or an invitation to plan.
class _HourBlock extends StatelessWidget {
  final int hour;
  final List<DayTask> tasks;
  final int nowMinutes;
  final void Function(DayTask task) onToggle;
  final VoidCallback onAdd;

  const _HourBlock({
    required this.hour,
    required this.tasks,
    required this.nowMinutes,
    required this.onToggle,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (tasks.isNotEmpty) {
      return Column(
        children: [
          for (final t in tasks)
            _RailRow(
              task: t,
              past: t.atMinutes! <= nowMinutes,
              onToggle: () => onToggle(t),
            ),
        ],
      );
    }

    // An hour already gone is drawn fainter and not offered: planning the past
    // is not a thing anyone wants to be invited to do.
    final past = (hour + 1) * 60 <= nowMinutes;
    return InkWell(
      onTap: past ? null : onAdd,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: TextStyle(
                  fontSize: 12,
                  color: past
                      ? scheme.outlineVariant
                      : scheme.outline,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: past ? 0.4 : 1),
              ),
            ),
            if (!past) ...[
              const SizedBox(width: 10),
              Icon(Icons.add, size: 16, color: scheme.outline),
            ],
          ],
        ),
      ),
    );
  }
}

class _RailRow extends StatelessWidget {
  final DayTask task;
  final bool past;
  final VoidCallback onToggle;

  const _RailRow({
    required this.task,
    required this.past,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = task.done || past;
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Text(
                task.isTimed ? task.timeLabel : '',
                style: TextStyle(
                  fontSize: 12,
                  color: muted ? scheme.outline : scheme.onSurface,
                ),
              ),
            ),
            Icon(
              task.done
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 19,
              color: task.done ? scheme.primary : scheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  decoration: task.done ? TextDecoration.lineThrough : null,
                  color: task.done ? scheme.outline : null,
                ),
              ),
            ),
            if (task.notify)
              Icon(Icons.notifications_active_outlined,
                  size: 16, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}

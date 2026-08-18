import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/health/domain/entities/activity_entry.dart';
import 'package:lifeos/features/health/presentation/providers/activity_providers.dart';
import 'package:lifeos/features/rooms/domain/life_room.dart';

/// Pick what you did and for how long.
///
/// Two taps and done: the kind, then a duration. Typing a number is offered
/// but never required — someone logging a walk on the way home is not going to
/// open a keyboard for it.
class ActivitySheet extends ConsumerStatefulWidget {
  const ActivitySheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const ActivitySheet(),
      );

  @override
  ConsumerState<ActivitySheet> createState() => _ActivitySheetState();
}

class _ActivitySheetState extends ConsumerState<ActivitySheet> {
  ActivityKind _kind = ActivityKind.walk;
  int _minutes = 30;
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _save() {
    final typed = int.tryParse(_custom.text.trim());
    final minutes = (typed != null && typed > 0) ? typed : _minutes;
    // A session cannot last a negative hour, and a stray "0" should not become
    // a row that says nothing.
    if (minutes <= 0) return;
    ref.read(activitiesProvider.notifier).add(_kind, minutes);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accent = roomById(RoomId.body).paper;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 4, 16, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('act.title'),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in ActivityKind.values)
                  ChoiceChip(
                    selected: _kind == kind,
                    onSelected: (_) => setState(() => _kind = kind),
                    avatar: Text(kind.emoji),
                    label: Text(context.tr(kind.labelKey)),
                    selectedColor:
                        Color.lerp(accent, scheme.surfaceContainerLowest, 0.82),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(context.tr('act.howLong'),
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final m in const [15, 30, 45, 60, 90])
                  ChoiceChip(
                    selected: _custom.text.isEmpty && _minutes == m,
                    onSelected: (_) => setState(() {
                      _minutes = m;
                      _custom.clear();
                    }),
                    label: Text(context.trp('act.minutes', {'n': m})),
                    selectedColor:
                        Color.lerp(accent, scheme.surfaceContainerLowest, 0.82),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _custom,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                labelText: context.tr('act.custom'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.tr('act.add')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

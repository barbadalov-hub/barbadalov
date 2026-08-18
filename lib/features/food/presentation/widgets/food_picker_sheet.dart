import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/food/data/meal_catalog.dart';
import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/presentation/providers/diet_providers.dart';
import 'package:lifeos/features/rooms/domain/life_room.dart';
import 'package:lifeos/shared/widgets/voice_input_button.dart';

/// Find a dish and log it, instead of typing five numbers by hand.
///
/// The app already shipped a catalogue of a hundred-odd dishes with real
/// per-serving nutrition — the diary just could not reach it, so logging a
/// bowl of porridge meant knowing its protein content off the top of your
/// head. Nobody does that twice.
class FoodPickerSheet extends ConsumerStatefulWidget {
  /// Which meal the food is being added to.
  final MealSlot slot;

  const FoodPickerSheet({required this.slot, super.key});

  static Future<void> show(BuildContext context, MealSlot slot) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => FoodPickerSheet(slot: slot),
      );

  @override
  ConsumerState<FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends ConsumerState<FoodPickerSheet> {
  final _query = TextEditingController();
  MealOption? _picked;
  double _portion = 1;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// Dishes matching the typed text, in the user's own language.
  ///
  /// The catalogue stores translation keys, so matching has to happen on the
  /// rendered name — searching the keys would only ever find English.
  List<MealOption> _matches(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    const all = MealCatalog.all;
    if (q.isEmpty) {
      // Start with what fits this meal, so opening the sheet at breakfast
      // does not offer a bowl of borsch first.
      final mine = all.where((m) => m.slot == widget.slot).toList();
      return (mine.isEmpty ? all : mine).take(12).toList();
    }
    return all
        .where((m) => context.tr(m.nameKey).toLowerCase().contains(q))
        .take(20)
        .toList();
  }

  NutritionFacts _scaled(NutritionFacts n) => NutritionFacts(
        kcal: (n.kcal * _portion).round(),
        proteinG: (n.proteinG * _portion).round(),
        fatG: (n.fatG * _portion).round(),
        carbsG: (n.carbsG * _portion).round(),
      );

  void _log() {
    final picked = _picked;
    if (picked == null) return;
    ref.read(manualFoodProvider.notifier).add(
          context.tr(picked.nameKey),
          _scaled(picked.nutrition),
          slot: widget.slot,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = roomById(RoomId.body).paper;
    final results = _matches(context);
    final picked = _picked;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 4, 16, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('diet.pickFood'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          TextField(
            controller: _query,
            autofocus: true,
            onChanged: (_) => setState(() => _picked = null),
            decoration: InputDecoration(
              isDense: true,
              hintText: context.tr('diet.searchFood'),
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: VoiceInputButton(
                controller: _query,
                onChanged: () => setState(() => _picked = null),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (picked == null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        context.tr('diet.noFoodFound'),
                        style: TextStyle(color: scheme.outline),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final m = results[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Text(m.emoji,
                              style: const TextStyle(fontSize: 22)),
                          title: Text(context.tr(m.nameKey)),
                          subtitle: Text(
                            '${m.nutrition.kcal} ${context.tr('diet.kcal')} · '
                            'Б ${m.nutrition.proteinG} · '
                            'Ж ${m.nutrition.fatG} · '
                            'У ${m.nutrition.carbsG}',
                            style: TextStyle(
                                fontSize: 12, color: scheme.outline),
                          ),
                          onTap: () => setState(() => _picked = m),
                        );
                      },
                    ),
            )
          else ...[
            Row(
              children: [
                Text(picked.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(context.tr(picked.nameKey),
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: context.tr('common.cancel'),
                  onPressed: () => setState(() => _picked = null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(context.tr('diet.portion'),
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final p in const [0.5, 1.0, 1.5, 2.0])
                  ChoiceChip(
                    selected: _portion == p,
                    onSelected: (_) => setState(() => _portion = p),
                    label: Text(p == p.roundToDouble()
                        ? '${p.toInt()}×'
                        : '${p.toString()}×'),
                    selectedColor: Color.lerp(
                        accent, scheme.surfaceContainerLowest, 0.82),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.trp('diet.willAdd', {
                'kcal': _scaled(picked.nutrition).kcal,
                'p': _scaled(picked.nutrition).proteinG,
                'f': _scaled(picked.nutrition).fatG,
                'c': _scaled(picked.nutrition).carbsG,
              }),
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _log,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.tr('diet.logIt')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

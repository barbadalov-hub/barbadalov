import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/ocr_gateway.dart';
import 'package:lifeos/features/food/data/barcode_food_lookup.dart';
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

  /// A packaged product found by barcode. Kept separately from [_picked]
  /// because it is measured in grams rather than in servings.
  ScannedProduct? _scanned;
  int _grams = 100;
  bool _scanning = false;

  Future<void> _scan() async {
    setState(() => _scanning = true);
    final code = await ocrGateway.scanBarcode(OcrSource.camera);
    if (!mounted) return;
    if (code == null) {
      setState(() => _scanning = false);
      _say('diet.barcodeUnread');
      return;
    }

    final lang = Localizations.localeOf(context).languageCode;
    final result = await ref.read(barcodeLookupProvider).find(code, lang: lang);
    if (!mounted) return;
    setState(() => _scanning = false);

    if (result.product != null) {
      setState(() {
        _scanned = result.product;
        _picked = null;
        // Use the packet's own serving when it declares one; 100 g is the
        // honest default because that is what the numbers are stated for.
        _grams = result.product!.servingG ?? 100;
      });
      return;
    }

    _say(switch (result.failure!) {
      // Naming the real reason matters: "no signal" is something the user can
      // act on, "not in the database" means stop waiting and type it.
      LookupFailure.offline => 'diet.barcodeOffline',
      LookupFailure.unknown => 'diet.barcodeUnknown',
      LookupFailure.noNutrition => 'diet.barcodeNoFacts',
    });
  }

  void _say(String key) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(context.tr(key))));

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
    final scanned = _scanned;
    if (scanned != null) {
      ref.read(manualFoodProvider.notifier).add(
            scanned.name,
            scanned.forGrams(_grams),
            slot: widget.slot,
          );
      Navigator.of(context).pop();
      return;
    }

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
          if (ocrGateway.available && _scanned == null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _scanning ? null : _scan,
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                style: TextButton.styleFrom(foregroundColor: accent),
                label: Text(context.tr(
                    _scanning ? 'diet.barcodeLooking' : 'diet.scanBarcode')),
              ),
            ),
          ],
          if (_scanned != null) ...[
            const SizedBox(height: 10),
            _ScannedProductCard(
              product: _scanned!,
              grams: _grams,
              accent: accent,
              onGrams: (g) => setState(() => _grams = g),
              onClear: () => setState(() => _scanned = null),
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
          const SizedBox(height: 10),
          if (_scanned == null && picked == null)
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
          else if (picked != null) ...[
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

/// A packaged product found by barcode: what it is, how much of it, and what
/// that adds up to.
class _ScannedProductCard extends StatelessWidget {
  final ScannedProduct product;
  final int grams;
  final Color accent;
  final ValueChanged<int> onGrams;
  final VoidCallback onClear;

  const _ScannedProductCard({
    required this.product,
    required this.grams,
    required this.accent,
    required this.onGrams,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final n = product.forGrams(grams);
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏷️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: context.tr('common.cancel'),
                onPressed: onClear,
              ),
            ],
          ),
          Text(
            // Say where the numbers came from. A figure off a packet is not
            // the same kind of fact as one the app itself put there.
            context.trp('diet.per100', {'kcal': product.per100.kcal}),
            style: TextStyle(fontSize: 12, color: scheme.outline),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final g in const [30, 50, 100, 150, 200])
                ChoiceChip(
                  selected: grams == g,
                  onSelected: (_) => onGrams(g),
                  label: Text('$g ${context.tr('diet.gram')}'),
                  selectedColor:
                      Color.lerp(accent, scheme.surfaceContainerLowest, 0.82),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.trp('diet.willAdd', {
              'kcal': n.kcal,
              'p': n.proteinG,
              'f': n.fatG,
              'c': n.carbsG,
            }),
            style: TextStyle(fontSize: 13, color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lifeos/shared/widgets/voice_input_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/doc_store.dart';
import 'package:lifeos/core/services/ocr_gateway.dart';
import 'package:lifeos/core/utils/share_image.dart';
import 'package:lifeos/features/money/domain/entities/purchase.dart';
import 'package:lifeos/features/money/presentation/providers/purchase_providers.dart';
import 'package:lifeos/features/rooms/domain/life_room.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';

/// The shelf of things you can still take back.
///
/// The scenario this exists for: the headphones die five months in, you assume
/// that is that, and then the app tells you the warranty runs another seven
/// months and hands you the receipt you photographed in the shop.
class WarrantyPage extends ConsumerWidget {
  const WarrantyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchases = ref.watch(purchasesByUrgencyProvider);
    final now = ref.watch(clockProvider).now();
    final accent = roomById(RoomId.money).colorFor(Theme.of(context).brightness);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('warranty.title'))),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-warranty',
        backgroundColor: roomById(RoomId.money).paper,
        foregroundColor: Colors.white,
        onPressed: () => PurchaseSheet.show(context),
        icon: Icon(ocrGateway.available
            ? Icons.document_scanner_outlined
            : Icons.add),
        label: Text(context.tr('warranty.add')),
      ),
      body: AnimatedBackdrop(
        style: BackdropStyle.galaxy,
        color: accent,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Text(
              context.tr('warranty.intro'),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 14),
            if (purchases.isEmpty)
              _EmptyShelf(accent: accent)
            else
              for (final p in purchases) ...[
                _PurchaseCard(purchase: p, now: now),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _EmptyShelf extends StatelessWidget {
  final Color accent;
  const _EmptyShelf({required this.accent});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('warranty.emptyTitle'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            context.tr('warranty.emptyBody'),
            style: TextStyle(
                fontSize: 13, height: 1.4, color: scheme.onSurface),
          ),
          if (!ocrGateway.available) ...[
            const SizedBox(height: 10),
            Text(
              // Better to say it than to show a camera button that does
              // nothing: the picker only exists on phones.
              context.tr('warranty.phoneOnly'),
              style: TextStyle(fontSize: 12, color: scheme.outline),
            ),
          ],
        ],
      ),
    );
  }
}

class _PurchaseCard extends ConsumerWidget {
  final Purchase purchase;
  final DateTime now;
  const _PurchaseCard({required this.purchase, required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final state = purchase.state(now);
    final tone = switch (state) {
      CoverState.endingSoon => LifeColors.warning,
      CoverState.ended => LifeColors.financeDanger,
      CoverState.covered => LifeColors.positive,
      CoverState.none => scheme.outline,
    };

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => PurchaseSheet.show(context, existing: purchase),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant, width: 0.5),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 30,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: tone,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          [
                            if (purchase.shop.isNotEmpty) purchase.shop,
                            DateFormat.yMMM(
                                    Localizations.localeOf(context).languageCode)
                                .format(purchase.boughtAt),
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12, color: scheme.outline),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(purchase.price.format(),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _statusLine(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: tone),
                    ),
                  ),
                  if (purchase.hasReceipt) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.receipt_long,
                        size: 17, color: scheme.outline),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLine(BuildContext context) {
    final days = purchase.daysLeft(now);
    if (days == null) return context.tr('warranty.stateUnknown');
    final lang = Localizations.localeOf(context).languageCode;
    final date = DateFormat.yMMMd(lang).format(purchase.until!);
    if (days < 0) {
      return context.trp(
          purchase.kind == CoverKind.warranty
              ? 'warranty.stateEnded'
              : 'warranty.stateSpoiled',
          {'date': date});
    }
    return context.trp(
      purchase.kind == CoverKind.warranty
          ? 'warranty.stateCovered'
          : 'warranty.stateFresh',
      {'date': date, 'days': days},
    );
  }
}

/// The kept receipt, shown rather than merely reported.
///
/// "The receipt is saved" is a claim; a thumbnail you can open is proof. If the
/// photo came out unreadable, the user needs to find that out in the shop's car
/// park — not eleven months later at the counter.
class _ReceiptStrip extends ConsumerWidget {
  /// A photo taken in this sheet and not yet written to disk.
  final Uint8List? fresh;

  /// A photo already on the shelf.
  final String? docId;
  final VoidCallback? onExport;

  const _ReceiptStrip({this.fresh, this.docId, this.onExport});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final stored = docId == null
        ? const AsyncValue<Uint8List?>.data(null)
        : ref.watch(receiptImageProvider(docId!));
    final bytes = fresh ?? stored.valueOrNull;

    return Row(
      children: [
        if (bytes != null)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _ReceiptViewer(bytes: bytes),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                bytes,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                // A corrupt file must not take the whole sheet down with it.
                errorBuilder: (_, __, ___) => Container(
                  width: 54,
                  height: 54,
                  color: scheme.surfaceContainerHighest,
                  child: Icon(Icons.broken_image_outlined,
                      size: 20, color: scheme.outline),
                ),
              ),
            ),
          )
        else
          const SizedBox(
            width: 54,
            height: 54,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            context.tr('warranty.receiptKept'),
            style: TextStyle(fontSize: 12.5, color: scheme.onSurface),
          ),
        ),
        if (onExport != null)
          TextButton(
            onPressed: onExport,
            child: Text(context.tr('warranty.export')),
          ),
      ],
    );
  }
}

/// The receipt at full size, zoomable — the print on a shop receipt is small
/// enough that a fixed-size view would be useless for reading the date.
class _ReceiptViewer extends StatelessWidget {
  final Uint8List bytes;
  const _ReceiptViewer({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('warranty.viewReceipt'))),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          maxScale: 6,
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Add or edit a kept purchase.
class PurchaseSheet extends ConsumerStatefulWidget {
  final Purchase? existing;
  const PurchaseSheet({this.existing, super.key});

  static Future<void> show(BuildContext context, {Purchase? existing}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => PurchaseSheet(existing: existing),
      );

  @override
  ConsumerState<PurchaseSheet> createState() => _PurchaseSheetState();
}

class _PurchaseSheetState extends ConsumerState<PurchaseSheet> {
  late final _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final _shop = TextEditingController(text: widget.existing?.shop ?? '');
  late final _price = TextEditingController(
      text: widget.existing == null
          ? ''
          : widget.existing!.price.major.toStringAsFixed(2));

  late DateTime _boughtAt = widget.existing?.boughtAt ?? DateTime.now();
  late CoverKind _kind = widget.existing?.kind ?? CoverKind.warranty;
  late DateTime? _until = widget.existing?.until;

  Uint8List? _photo;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _shop.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _scan(OcrSource source) async {
    setState(() => _busy = true);
    final doc = await ocrGateway.captureDocument(source);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (doc != null) _photo = doc.bytes;
    });
  }

  /// Months are how warranties are actually quoted, so the picker offers them
  /// and turns them into a date rather than making the user count.
  void _setMonths(int months) => setState(
      () => _until = Purchase.addMonths(_boughtAt, months));

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final major = double.tryParse(_price.text.replaceAll(',', '.')) ?? 0;

    final controller = ref.read(purchasesProvider.notifier);
    if (widget.existing == null) {
      await controller.add(
        title: title,
        shop: _shop.text,
        price: Money.fromMajor(major),
        boughtAt: _boughtAt,
        until: _until,
        kind: _kind,
        receiptBytes: _photo,
      );
    } else {
      var next = widget.existing!.copyWith(
        title: title,
        shop: _shop.text.trim(),
        price: Money.fromMajor(major),
        boughtAt: _boughtAt,
        kind: _kind,
        until: _until,
        clearUntil: _until == null,
      );
      if (_photo != null) {
        final id = await docStore.save(widget.existing!.id, _photo!);
        if (id != null) next = next.copyWith(receiptDocId: id);
      }
      controller.update(next);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final lang = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 4, 16, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(existing == null ? 'warranty.add' : 'warranty.edit'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (ocrGateway.available) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _busy ? null : () => _scan(OcrSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: Text(context.tr('warranty.photograph')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _busy ? null : () => _scan(OcrSource.gallery),
                    tooltip: context.tr('warranty.fromGallery'),
                    icon: const Icon(Icons.image_outlined),
                  ),
                ],
              ),
              if (_photo != null || existing?.hasReceipt == true) ...[
                const SizedBox(height: 10),
                _ReceiptStrip(
                  fresh: _photo,
                  docId: existing?.receiptDocId,
                  onExport:
                      existing?.receiptDocId == null ? null : () => _export(existing!),
                ),
              ],
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _title,
              autofocus: existing == null,
              decoration: InputDecoration(
                labelText: context.tr('warranty.what'),
                border: const OutlineInputBorder(),
                suffixIcon: VoiceInputButton(controller: _title),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _shop,
                    decoration: InputDecoration(
                      labelText: context.tr('warranty.shop'),
                      border: const OutlineInputBorder(),
                      suffixIcon: VoiceInputButton(controller: _shop),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: context.tr('warranty.price'),
                        border: const OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<CoverKind>(
              segments: [
                ButtonSegment(
                  value: CoverKind.warranty,
                  label: Text(context.tr('warranty.kindWarranty')),
                ),
                ButtonSegment(
                  value: CoverKind.expiry,
                  label: Text(context.tr('warranty.kindExpiry')),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.shopping_bag_outlined),
              title: Text(context.tr('warranty.bought')),
              subtitle: Text(DateFormat.yMMMd(lang).format(_boughtAt)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _boughtAt,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _boughtAt = picked);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available_outlined),
              title: Text(context.tr(_kind == CoverKind.warranty
                  ? 'warranty.until'
                  : 'warranty.goodUntil')),
              subtitle: Text(_until == null
                  ? context.tr('warranty.notSet')
                  : DateFormat.yMMMd(lang).format(_until!)),
              trailing: _until == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _until = null),
                    ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _until ?? Purchase.addMonths(_boughtAt, 12),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _until = picked);
              },
            ),
            if (_kind == CoverKind.warranty)
              Wrap(
                spacing: 8,
                children: [
                  for (final months in const [6, 12, 24, 36])
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                          context.trp('warranty.months', {'n': months})),
                      onPressed: () => _setMonths(months),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (existing != null)
                  TextButton.icon(
                    onPressed: () async {
                      await ref
                          .read(purchasesProvider.notifier)
                          .remove(existing.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(context.tr('common.delete')),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text(context.tr('common.save')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Hands the stored photo back as a file: the paper is long gone by the time
  /// anyone needs it, and a receipt locked inside an app is not proof of
  /// anything at the counter.
  Future<void> _export(Purchase p) async {
    final bytes = await docStore.load(p.receiptDocId!);
    if (bytes == null) return;
    final stamp = DateFormat('yyyy-MM-dd').format(p.boughtAt);
    final safe = p.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final ok = await shareImage(
        'receipt-${safe.isEmpty ? p.id : safe}-$stamp.jpg', bytes);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(context.tr(
            ok ? 'warranty.exported' : 'warranty.exportFailed')),
      ));
  }
}

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/utils/share_image.dart';

/// Captures the [RepaintBoundary] at [boundaryKey] as a PNG (3× density) and
/// shares it (web download / native save+open), then shows a result snackbar.
/// Set [popAfter] to also dismiss the surrounding sheet once captured.
Future<void> shareBoundaryPng(
  BuildContext context,
  GlobalKey boundaryKey,
  String filename, {
  bool popAfter = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final okMsg = context.tr('wrapped.saved');
  final failMsg = context.tr('wrapped.shareFail');
  try {
    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final ok = bytes != null &&
        await shareImage(filename, bytes.buffer.asUint8List());
    if (popAfter && context.mounted) Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(ok ? okMsg : failMsg)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failMsg)));
  }
}

/// The shared cosmos "share card" used by Wrapped, Insights and the weekly
/// report. Wrap it in a [RepaintBoundary] and hand the key to [shareBoundaryPng].
/// Supply either [rows] (emoji · label · value) or [lines] (bullet strings).
class ShareCard extends StatelessWidget {
  final String emoji;

  /// Optional small letter-spaced line above the title (e.g. "LifeOS Wrapped").
  final String? kicker;
  final String title;
  final double titleSize;
  final List<(String, String, String)>? rows;
  final List<String>? lines;

  const ShareCard({
    required this.emoji,
    required this.title,
    this.kicker,
    this.titleSize = 20,
    this.rows,
    this.lines,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1A5E), Color(0xFF0A0518)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          if (kicker != null)
            Text(
              kicker!.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (rows != null)
            for (final (rowEmoji, label, value) in rows!)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(rowEmoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.75))),
                    ),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ],
                ),
              ),
          if (lines != null)
            for (final line in lines!)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•',
                        style:
                            TextStyle(color: Color(0xFF7BF7FF), fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(line,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14, height: 1.35)),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 16),
          Text('lifeos',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  color: Colors.white.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}

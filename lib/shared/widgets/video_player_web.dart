import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final _registered = <String>{};

/// Play an mp4/MOV inside the app — web variant. Uses a plain HTML `<video>`
/// element through Flutter's built-in HtmlElementView (no plugin): media
/// elements play cross-origin without CORS, and nothing leaves the app, so
/// even sandboxed previews that block external links can play it.
Future<void> playVideo(BuildContext context, String url, String title) async {
  final viewType = 'lifeos-video-${url.hashCode}';
  if (!_registered.contains(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      return web.HTMLVideoElement()
        ..src = url
        ..controls = true
        ..autoplay = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..style.background = 'black';
    });
    _registered.add(viewType);
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: HtmlElementView(viewType: viewType),
            ),
          ),
        ],
      ),
    ),
  );
}

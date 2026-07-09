import 'dart:convert';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Downloads [bytes] as a PNG named [filename] via a base64 data-URL anchor —
/// plugin-free and popup-blocker friendly.
Future<bool> shareImage(String filename, Uint8List bytes) async {
  final href = 'data:image/png;base64,${base64Encode(bytes)}';
  final anchor = web.HTMLAnchorElement()
    ..href = href
    ..download = filename;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  return true;
}

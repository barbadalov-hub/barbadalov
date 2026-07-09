import 'dart:io';
import 'dart:typed_data';

import 'package:lifeos/core/utils/open_url.dart';

/// Writes [bytes] to a PNG file in the temp dir and opens it in the system image
/// viewer — desktop/mobile (`dart:io`) variant, no share/file plugin needed.
Future<bool> shareImage(String filename, Uint8List bytes) async {
  try {
    final path = '${Directory.systemTemp.path}${Platform.pathSeparator}$filename';
    await File(path).writeAsBytes(bytes, flush: true);
    await openUrl(path);
    return true;
  } catch (_) {
    return false;
  }
}

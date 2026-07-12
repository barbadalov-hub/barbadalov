import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Opens the browser file picker and returns the chosen text file's contents,
/// or null if the user cancels or the read fails. Plugin-free (`package:web`).
Future<String?> pickTextFile() {
  final completer = Completer<String?>();
  final input =
      (web.document.createElement('input') as web.HTMLInputElement)
        ..type = 'file'
        ..accept = '.json,application/json';

  input.onchange = (web.Event _) {
    final files = input.files;
    if (files == null || files.length == 0) {
      completer.complete(null);
      return;
    }
    final reader = web.FileReader();
    reader.onload = (web.Event _) {
      final res = reader.result;
      completer.complete(
          res != null && res.isA<JSString>() ? (res as JSString).toDart : null);
    }.toJS;
    reader.onerror = ((web.Event _) => completer.complete(null)).toJS;
    reader.readAsText(files.item(0)!);
  }.toJS;

  input.click();
  return completer.future;
}

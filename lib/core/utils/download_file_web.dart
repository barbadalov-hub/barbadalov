import 'package:web/web.dart' as web;

/// Downloads [content] as a file named [filename] via a synthetic anchor with a
/// data URL — plugin-free, and popup-blocker/preview friendly.
bool downloadTextFile(String filename, String content) {
  final href =
      'data:application/json;charset=utf-8,${Uri.encodeComponent(content)}';
  final anchor = web.HTMLAnchorElement()
    ..href = href
    ..download = filename;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  return true;
}

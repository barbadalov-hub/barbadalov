import 'package:web/web.dart' as web;

/// Open [url] in a new browser tab — web variant. Uses a synthetic anchor
/// click instead of `window.open`, which popup blockers (and embedded
/// previews) are far more willing to allow.
Future<void> openUrl(String url) async {
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..target = '_blank'
    ..rel = 'noopener';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}

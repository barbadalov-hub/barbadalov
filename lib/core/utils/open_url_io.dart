import 'dart:io';

/// Open [url] in the system browser — desktop/mobile (`dart:io`) variant.
/// No url_launcher plugin, so the plugin-free Windows build stays intact.
Future<void> openUrl(String url) async {
  if (Platform.isWindows) {
    await Process.run('rundll32', ['url.dll,FileProtocolHandler', url]);
  } else if (Platform.isMacOS) {
    await Process.run('open', [url]);
  } else {
    await Process.run('xdg-open', [url]);
  }
}

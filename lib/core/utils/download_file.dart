/// Trigger a browser download of a text file on web; a no-op on native
/// (desktop/mobile use the clipboard path instead). Conditional export keeps
/// the web-only `package:web` code out of native builds.
library;

export 'download_file_web.dart' if (dart.library.io) 'download_file_io.dart';

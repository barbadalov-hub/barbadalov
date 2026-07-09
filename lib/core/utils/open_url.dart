// Platform-agnostic "open in browser" — used for workout videos so they load
// only when the user actually plays them, with zero plugins.
export 'open_url_web.dart' if (dart.library.io) 'open_url_io.dart';

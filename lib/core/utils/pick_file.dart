/// Open a file picker and return a text file's contents on web; null on native
/// (desktop/mobile use the paste path instead). Conditional export keeps the
/// web-only `package:web` code out of native builds.
library;

export 'pick_file_web.dart' if (dart.library.io) 'pick_file_io.dart';

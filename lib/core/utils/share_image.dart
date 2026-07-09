/// Save/share a PNG image the user just generated (e.g. a Wrapped card).
/// Plugin-free: web triggers a browser download, native writes a file and opens
/// it in the system viewer. Conditional export keeps `package:web` out of native
/// builds and `dart:io` out of the web build.
library;

export 'share_image_web.dart' if (dart.library.io) 'share_image_io.dart';

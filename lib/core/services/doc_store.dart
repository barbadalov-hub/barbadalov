/// Cross-platform seam for **keeping a scanned document on the device**.
///
/// A receipt is worth nothing if it disappears with the app's cache, so these
/// files live beside the user's data rather than in the temp directory. Native
/// builds write real files; web has no camera path at all (see `ocr_gateway`),
/// so it resolves to a backend that stores nothing and says so.
///
/// Consumers `import 'doc_store.dart'` and use `docStore`.
library;

export 'doc_store_noop.dart' if (dart.library.io) 'doc_store_io.dart';

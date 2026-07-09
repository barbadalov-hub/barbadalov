/// Cross-platform seam for **receipt photo OCR**.
///
/// Real OCR runs only on phones (Android/iOS) via on-device ML Kit — free, no
/// account, no network. On web and desktop this resolves to a no-op backend
/// (`available == false`), so those builds never import the mobile-only plugins
/// and keep the text-paste flow instead.
///
/// Consumers `import 'ocr_gateway.dart'` and use `ocrGateway`; the conditional
/// export picks the right backend.
library;

export 'ocr_gateway_noop.dart'
    if (dart.library.io) 'ocr_gateway_io.dart';

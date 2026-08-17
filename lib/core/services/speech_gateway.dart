/// Cross-platform seam for **dictating into a text field**.
///
/// Real recognition runs only on phones (Android/iOS) through the device's own
/// speech engine — free, no account, no API key, and on most devices no network
/// either. Desktop and web resolve to a backend that reports `available ==
/// false`, so those builds never touch the mobile-only plugin and keep typing.
///
/// Consumers `import 'speech_gateway.dart'` and use `speechGateway`.
library;

export 'speech_gateway_noop.dart'
    if (dart.library.io) 'speech_gateway_io.dart';

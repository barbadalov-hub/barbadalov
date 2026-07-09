/// Cross-platform seam for **Google sign-in**.
///
/// Implemented on web via Google Identity Services (plugin-free — a script +
/// `dart:js_interop`). On desktop/mobile there is no plugin-free Google flow, so
/// it resolves to a stub (`available == false`) and those platforms use
/// email / anonymous sign-in instead.
///
/// Consumers `import 'google_auth_gateway.dart'` and use `googleAuthGateway`.
library;

export 'google_auth_gateway_stub.dart'
    if (dart.library.js_interop) 'google_auth_gateway_web.dart';

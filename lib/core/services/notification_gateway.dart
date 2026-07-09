/// Cross-platform seam for **OS-level notifications**.
///
/// Only phones get real system notifications (Android/iOS via
/// `flutter_local_notifications`). On web and desktop this resolves to a no-op
/// implementation, so:
///   * the web build never imports the (native-only) plugin, and
///   * the Windows build stays plugin-free — the plugin ships no Windows
///     native code, and the desktop badge (unread count in the UI) covers the
///     "something arrived" cue instead.
///
/// Consumers just `import 'notification_gateway.dart'` and use
/// `notificationGateway`; the conditional export picks the right backend.
library;

export 'notification_gateway_noop.dart'
    if (dart.library.io) 'notification_gateway_io.dart';

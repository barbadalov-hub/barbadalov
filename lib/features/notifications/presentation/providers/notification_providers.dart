import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/i18n/locale_controller.dart';
import 'package:lifeos/core/services/notification_gateway.dart';
import 'package:lifeos/features/notifications/data/notification_repository_impl.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_prefs.dart';
import 'package:lifeos/features/notifications/domain/entities/app_notification.dart';
import 'package:lifeos/features/notifications/domain/repositories/notification_repository.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Single notification store instance for the app. Each new notification is
/// also pushed to the OS on phones (no-op on web/desktop), localized to the
/// user's current language via the i18n keys the notification carries.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final impl = NotificationRepositoryImpl(
    onAdded: (n) {
      // Suppress the phone push during quiet hours (the in-app feed still keeps
      // it). The badge/feed always update.
      final prefs = ref.read(notificationPrefsProvider);
      if (prefs.quietAt(ref.read(clockProvider).now().hour)) return;
      final lang = ref.read(localeProvider)?.languageCode ?? 'en';
      final t = AppLocalizations(lang);
      notificationGateway.show(
        id: n.id.hashCode & 0x7fffffff,
        title: t.tr(n.titleKey),
        body: t.trp(n.bodyKey, n.params),
      );
    },
  );
  ref.onDispose(impl.dispose);
  return impl;
});

/// Live notification feed. Touches [coreEngineProvider] so the handler that
/// fills this store is running.
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  ref.watch(coreEngineProvider);
  return ref.watch(notificationRepositoryProvider).watch();
});

/// Count of unread notifications, for the Today-screen badge.
final unreadCountProvider = Provider<int>((ref) {
  final items = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return items.where((n) => !n.read).length;
});

/// Notifications-screen filter: null = all, otherwise a specific tier.
final notifFilterProvider = StateProvider<NotificationTier?>((ref) => null);

/// When true, only unread notifications are shown.
final notifUnreadOnlyProvider = StateProvider<bool>((ref) => false);

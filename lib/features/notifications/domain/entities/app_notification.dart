import 'package:equatable/equatable.dart';

/// Priority tiers from the spec. Colour/ordering is derived from this.
enum NotificationTier {
  critical, // 🔴 financial risk, health alerts
  important, // 🟡 budget, groceries, tasks
  optional, // 🟢 habits, learning
  aiInsight, // 🤖 forecasts, recommendations
}

/// A user-facing notification. Like [AiInsight], it carries **i18n keys +
/// params** instead of prose, so notifications generated inside event handlers
/// (no BuildContext) still render in the user's language.
class AppNotification extends Equatable {
  final String id;
  final NotificationTier tier;
  final String titleKey;
  final String bodyKey;
  final Map<String, Object> params;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.tier,
    required this.titleKey,
    required this.bodyKey,
    required this.createdAt,
    this.params = const {},
    this.read = false,
  });

  AppNotification markRead() => AppNotification(
        id: id,
        tier: tier,
        titleKey: titleKey,
        bodyKey: bodyKey,
        params: params,
        createdAt: createdAt,
        read: true,
      );

  @override
  List<Object?> get props =>
      [id, tier, titleKey, bodyKey, params, createdAt, read];
}

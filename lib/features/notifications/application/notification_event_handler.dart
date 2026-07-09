import 'package:lifeos/core/events/event_handler.dart';
import 'package:lifeos/core/events/life_event.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/id_service.dart';
import 'package:lifeos/features/notifications/domain/entities/app_notification.dart';
import 'package:lifeos/features/notifications/domain/repositories/notification_repository.dart';
import 'package:lifeos/shared/models/money.dart';

/// Turns raw life events into user-facing notifications. Registered with the
/// [LifeCoreEngine], so notifications are a *reaction to the event stream* — no
/// feature calls the notification system directly. It stays decoupled from
/// feature types by reading each event's [LifeEvent.toPayload] map, and emits
/// i18n keys + params so the UI renders them in the app language.
class NotificationEventHandler implements EventHandler {
  final NotificationRepository _repository;
  final IdService _idService;
  final Clock _clock;

  const NotificationEventHandler(
    this._repository,
    this._idService,
    this._clock,
  );

  /// $200 — an expense above this earns an IMPORTANT nudge.
  static const _largeExpenseMinorUnits = 20000;

  /// 2h of headphone listening in a day earns an OPTIONAL rest reminder (§14).
  static const _listeningThresholdMinutes = 120;

  @override
  String get name => 'Notifications';

  @override
  bool canHandle(LifeEvent event) =>
      event.type == 'expense_added' ||
      event.type == 'income_added' ||
      event.type == 'listening_logged';

  @override
  Future<void> handle(LifeEvent event) async {
    final payload = event.toPayload();

    switch (event.type) {
      case 'expense_added' || 'income_added':
        final minor = (payload['amountMinorUnits'] as int?) ?? 0;
        final currency = (payload['currency'] as String?) ?? 'USD';
        final amount = Money(minor, currency: currency);
        if (event.type == 'expense_added' &&
            minor >= _largeExpenseMinorUnits) {
          _push(
            NotificationTier.important,
            'notifMsg.largeExpense.title',
            'notifMsg.largeExpense.body',
            {'amount': amount.format()},
          );
        } else if (event.type == 'income_added') {
          _push(
            NotificationTier.optional,
            'notifMsg.income.title',
            'notifMsg.income.body',
            {'amount': amount.format()},
          );
        }
      case 'listening_logged':
        final total = (payload['totalMinutes'] as int?) ?? 0;
        final added = (payload['addedMinutes'] as int?) ?? 0;
        // Fire once, when the day's total crosses the threshold.
        if (total >= _listeningThresholdMinutes &&
            total - added < _listeningThresholdMinutes) {
          _push(
            NotificationTier.optional,
            'notifMsg.ears.title',
            'notifMsg.ears.body',
            {'minutes': total},
          );
        }
    }
  }

  void _push(
    NotificationTier tier,
    String titleKey,
    String bodyKey,
    Map<String, Object> params,
  ) {
    _repository.add(AppNotification(
      id: _idService.newId(),
      tier: tier,
      titleKey: titleKey,
      bodyKey: bodyKey,
      params: params,
      createdAt: _clock.now(),
    ));
  }
}

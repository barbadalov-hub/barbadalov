/// The single, non-negotiable unit of change in LifeOS.
///
/// Every user action becomes a [LifeEvent] — `expense_added`, `water_logged`,
/// `sleep_logged`, `goal_updated`, ... There are no exceptions to this rule.
/// Concrete events are declared *inside their own feature* (e.g. MoneyOS owns
/// `ExpenseAddedEvent`) so that `core` never depends on a feature. `core` only
/// knows this abstract contract.
abstract class LifeEvent {
  /// Unique id of this event occurrence.
  final String id;

  /// When the event actually happened (may differ from when it was recorded).
  final DateTime occurredAt;

  /// Owner of the event.
  final String userId;

  const LifeEvent({
    required this.id,
    required this.occurredAt,
    required this.userId,
  });

  /// Stable machine name, e.g. `expense_added`. Used for routing, persistence
  /// to the `events/` collection, and analytics.
  String get type;

  /// Serialisable payload persisted to the append-only event log.
  Map<String, dynamic> toPayload();

  /// Envelope actually written to storage / streamed on the bus.
  Map<String, dynamic> toEnvelope() => {
        'id': id,
        'type': type,
        'userId': userId,
        'occurredAt': occurredAt.toIso8601String(),
        'payload': toPayload(),
      };
}

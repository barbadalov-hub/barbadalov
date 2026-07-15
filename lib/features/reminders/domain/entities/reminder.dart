import 'package:equatable/equatable.dart';

/// A daily reminder the user configures. Fires as a real OS notification on
/// phones (even when the app is closed) and shows in the in-app feed elsewhere.
enum ReminderKind {
  water('reminder.kind.water', '💧', 10, 0),
  meal('reminder.kind.meal', '🍽️', 13, 0),
  workout('reminder.kind.workout', '🏋️', 18, 0),
  meds('reminder.kind.meds', '💊', 9, 0),
  budget('reminder.kind.budget', '💸', 20, 0),
  sleep('reminder.kind.sleep', '😴', 22, 30),
  checkin('reminder.kind.checkin', '📝', 21, 0),
  custom('reminder.kind.custom', '⏰', 12, 0);

  const ReminderKind(this.labelKey, this.emoji, this.defaultHour,
      this.defaultMinute);

  /// i18n key for the built-in label (ignored for [custom]).
  final String labelKey;
  final String emoji;
  final int defaultHour;
  final int defaultMinute;

  static ReminderKind fromName(String name) => values.firstWhere(
        (k) => k.name == name,
        orElse: () => ReminderKind.custom,
      );
}

class Reminder extends Equatable {
  final String id;
  final ReminderKind kind;

  /// Free text for [ReminderKind.custom]; ignored for built-in kinds.
  final String customLabel;
  final int hour;
  final int minute;
  final bool enabled;

  const Reminder({
    required this.id,
    required this.kind,
    this.customLabel = '',
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  /// A stable positive notification id derived from the reminder id.
  int get notificationId => id.hashCode & 0x7fffffff;

  /// `"HH:MM"` for display.
  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Reminder copyWith({
    ReminderKind? kind,
    String? customLabel,
    int? hour,
    int? minute,
    bool? enabled,
  }) =>
      Reminder(
        id: id,
        kind: kind ?? this.kind,
        customLabel: customLabel ?? this.customLabel,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'customLabel': customLabel,
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] as String,
        kind: ReminderKind.fromName(j['kind'] as String? ?? 'custom'),
        customLabel: j['customLabel'] as String? ?? '',
        hour: (j['hour'] as num?)?.toInt() ?? 12,
        minute: (j['minute'] as num?)?.toInt() ?? 0,
        enabled: j['enabled'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [id, kind, customLabel, hour, minute, enabled];
}

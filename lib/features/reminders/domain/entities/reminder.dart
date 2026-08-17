import 'package:equatable/equatable.dart';

/// A daily reminder the user configures. Fires as a real OS notification on
/// phones (even when the app is closed) and shows in the in-app feed elsewhere.
enum ReminderKind {
  // Water and movement are useless as a single daily ping — being told to
  // drink at 10:00 and nothing after does not change a day. They default to
  // repeating across the waking hours instead.
  water('reminder.kind.water', '💧', 9, 0, every: 120, untilHour: 21),
  move('reminder.kind.move', '🚶', 10, 0, every: 90, untilHour: 18),
  posture('reminder.kind.posture', '🪑', 10, 30, every: 120, untilHour: 18),
  eyes('reminder.kind.eyes', '👀', 11, 0, every: 120, untilHour: 19),
  meal('reminder.kind.meal', '🍽️', 13, 0),
  workout('reminder.kind.workout', '🏋️', 18, 0),
  meds('reminder.kind.meds', '💊', 9, 0),
  budget('reminder.kind.budget', '💸', 20, 0),
  sleep('reminder.kind.sleep', '😴', 22, 30),
  checkin('reminder.kind.checkin', '📝', 21, 0),
  custom('reminder.kind.custom', '⏰', 12, 0);

  const ReminderKind(
    this.labelKey,
    this.emoji,
    this.defaultHour,
    this.defaultMinute, {
    this.every = 0,
    this.untilHour = 0,
  });

  /// i18n key for the built-in label (ignored for [custom]). This is the text
  /// the notification itself carries, so it is a full instruction.
  final String labelKey;

  /// One or two words for a chip. The notification says "Get up and walk a
  /// little"; a button cannot, and trying made the shelf overflow.
  /// Only the [care] kinds are guaranteed to have one.
  String get shortKey => 'reminder.short.$name';
  final String emoji;
  final int defaultHour;
  final int defaultMinute;

  /// Minutes between repeats; 0 means it fires once a day.
  final int every;

  /// Hour the repeating window closes (inclusive of a fire exactly on it).
  final int untilHour;

  /// Kinds that belong to the body, offered inside the Body room rather than
  /// buried in the general reminders list.
  static const care = [water, move, posture, eyes, meal, meds];

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
  /// When it first fires.
  final int hour;
  final int minute;
  final bool enabled;

  /// Minutes between repeats through the day; 0 fires once.
  final int everyMinutes;

  /// Hour the repeating window closes. Ignored when [everyMinutes] is 0.
  final int untilHour;

  const Reminder({
    required this.id,
    required this.kind,
    this.customLabel = '',
    required this.hour,
    required this.minute,
    this.enabled = true,
    this.everyMinutes = 0,
    this.untilHour = 0,
  });

  /// A stable positive notification id derived from the reminder id. A
  /// repeating reminder occupies [notificationId] + n, one per occurrence,
  /// which is why ids are spaced by [idSpan] rather than packed.
  int get notificationId => (id.hashCode & 0x7fffffff) ~/ idSpan * idSpan;

  /// Ids reserved per reminder — also the hard cap on occurrences, so a
  /// misconfigured "every 1 minute" can never flood the OS scheduler.
  static const idSpan = 24;

  bool get repeats => everyMinutes > 0;

  /// Every wall-clock time this reminder fires today, first one included.
  ///
  /// Pure and total: an interval of zero, a window that ends before it starts,
  /// or a silly interval all collapse to a single fire rather than throwing or
  /// looping forever.
  List<({int hour, int minute})> get occurrences {
    final first = (hour: hour, minute: minute);
    if (everyMinutes <= 0) return [first];

    final startM = hour * 60 + minute;
    final endM = untilHour * 60;
    if (endM <= startM) return [first];

    final out = <({int hour, int minute})>[];
    for (var m = startM; m <= endM && out.length < idSpan; m += everyMinutes) {
      out.add((hour: m ~/ 60, minute: m % 60));
    }
    return out;
  }

  /// `"HH:MM"` for display, or `"HH:MM – HH:MM"` for a repeating window.
  String get timeLabel {
    String hhmm(int h, int m) =>
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    if (!repeats) return hhmm(hour, minute);
    final last = occurrences.last;
    return '${hhmm(hour, minute)} – ${hhmm(last.hour, last.minute)}';
  }

  Reminder copyWith({
    ReminderKind? kind,
    String? customLabel,
    int? hour,
    int? minute,
    bool? enabled,
    int? everyMinutes,
    int? untilHour,
  }) =>
      Reminder(
        id: id,
        kind: kind ?? this.kind,
        customLabel: customLabel ?? this.customLabel,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        enabled: enabled ?? this.enabled,
        everyMinutes: everyMinutes ?? this.everyMinutes,
        untilHour: untilHour ?? this.untilHour,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'customLabel': customLabel,
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
        'everyMinutes': everyMinutes,
        'untilHour': untilHour,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] as String,
        kind: ReminderKind.fromName(j['kind'] as String? ?? 'custom'),
        customLabel: j['customLabel'] as String? ?? '',
        hour: (j['hour'] as num?)?.toInt() ?? 12,
        minute: (j['minute'] as num?)?.toInt() ?? 0,
        enabled: j['enabled'] as bool? ?? true,
        // Reminders saved before repeats existed simply stay one-shot.
        everyMinutes: (j['everyMinutes'] as num?)?.toInt() ?? 0,
        untilHour: (j['untilHour'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props =>
      [id, kind, customLabel, hour, minute, enabled, everyMinutes, untilHour];
}

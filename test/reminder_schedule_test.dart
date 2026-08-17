import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/reminders/domain/entities/reminder.dart';

Reminder _r({
  required int hour,
  int minute = 0,
  int every = 0,
  int until = 0,
  ReminderKind kind = ReminderKind.custom,
}) =>
    Reminder(
      id: 'r-$hour-$minute-$every-$until',
      kind: kind,
      hour: hour,
      minute: minute,
      everyMinutes: every,
      untilHour: until,
    );

void main() {
  group('when a reminder fires', () {
    test('a plain reminder fires once', () {
      expect(_r(hour: 9, minute: 30).occurrences, [(hour: 9, minute: 30)]);
    });

    test('a repeating one walks its window', () {
      final water = _r(hour: 9, every: 120, until: 15);
      expect(water.occurrences, [
        (hour: 9, minute: 0),
        (hour: 11, minute: 0),
        (hour: 13, minute: 0),
        (hour: 15, minute: 0),
      ]);
    });

    test('intervals that do not divide the window stop inside it', () {
      final move = _r(hour: 10, every: 90, until: 14);
      expect(move.occurrences, [
        (hour: 10, minute: 0),
        (hour: 11, minute: 30),
        (hour: 13, minute: 0),
      ]);
      expect(move.timeLabel, '10:00 – 13:00');
    });
  });

  group('a phone can never be flooded', () {
    test('a silly interval is capped, not obeyed', () {
      // Someone setting "every minute, all day" must not get 900 OS
      // notifications — and must not silently claim another reminder's ids.
      final absurd = _r(hour: 0, every: 1, until: 23);
      expect(absurd.occurrences.length, Reminder.idSpan);
    });

    test('a window that ends before it starts collapses to one fire', () {
      expect(_r(hour: 20, every: 60, until: 8).occurrences.length, 1);
      expect(_r(hour: 9, every: 0, until: 18).occurrences.length, 1);
    });

    test('negative or zero intervals do not loop forever', () {
      expect(_r(hour: 9, every: -30, until: 18).occurrences.length, 1);
    });
  });

  group('notification ids', () {
    test('every occurrence gets its own id inside the reminder block', () {
      final r = _r(hour: 9, every: 120, until: 21);
      final ids = {for (var i = 0; i < r.occurrences.length; i++) r.notificationId + i};
      expect(ids.length, r.occurrences.length);
      expect(r.occurrences.length, lessThanOrEqualTo(Reminder.idSpan));
    });

    test('blocks are aligned so two reminders can never overlap', () {
      // Ids are spaced by idSpan, so reminder A's occurrence 5 can never land
      // on reminder B's occurrence 0 and cancel it.
      final ids = <int>{};
      for (var i = 0; i < 400; i++) {
        final base = Reminder(
          id: 'reminder-$i',
          kind: ReminderKind.water,
          hour: 9,
          minute: 0,
        ).notificationId;
        expect(base % Reminder.idSpan, 0, reason: 'block $i is misaligned');
        ids.add(base);
      }
      // Hash collisions are possible in principle; they must be rare enough
      // not to matter, not merely unproven.
      expect(ids.length, greaterThan(390));
    });
  });

  group('the care kinds carry sensible defaults', () {
    test('water and movement repeat, one-shot kinds do not', () {
      expect(ReminderKind.water.every, greaterThan(0));
      expect(ReminderKind.move.every, greaterThan(0));
      expect(ReminderKind.meds.every, 0,
          reason: 'medication is taken on a schedule, not every 90 minutes');
      expect(ReminderKind.sleep.every, 0);
    });

    test('every repeating kind closes its window after it opens', () {
      for (final k in ReminderKind.values.where((k) => k.every > 0)) {
        expect(k.untilHour * 60, greaterThan(k.defaultHour * 60 + k.defaultMinute),
            reason: '${k.name} would only ever fire once');
      }
    });
  });

  group('stored reminders survive the upgrade', () {
    test('a reminder saved before repeats existed stays one-shot', () {
      final old = Reminder.fromJson(const {
        'id': 'x',
        'kind': 'water',
        'customLabel': '',
        'hour': 10,
        'minute': 0,
        'enabled': true,
      });
      expect(old.repeats, isFalse);
      expect(old.occurrences.length, 1);
    });

    test('a repeating reminder round-trips through storage', () {
      final r = _r(hour: 9, every: 120, until: 21, kind: ReminderKind.water);
      expect(Reminder.fromJson(r.toJson()), r);
    });
  });
}

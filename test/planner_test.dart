import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/mind/domain/entities/day_task.dart';

void main() {
  group('a task with a time', () {
    const task = DayTask(
      id: 'a',
      title: 'Deep work',
      atMinutes: 8 * 60 + 5,
      notify: true,
    );

    test('exposes the hour and a padded label', () {
      expect(task.isTimed, isTrue);
      expect(task.hour, 8);
      expect(task.timeLabel, '08:05');
    });

    test('midnight and the last minute of the day both format', () {
      expect(const DayTask(id: 'x', title: 't', atMinutes: 0).timeLabel,
          '00:00');
      expect(
          const DayTask(id: 'x', title: 't', atMinutes: 23 * 60 + 59).timeLabel,
          '23:59');
    });

    test('has a stable, positive notification id', () {
      expect(task.notificationId, greaterThanOrEqualTo(0));
      expect(task.notificationId,
          const DayTask(id: 'a', title: 'other').notificationId,
          reason: 'the id derives from the task id, not its contents');
    });
  });

  group('an untimed task', () {
    const task = DayTask(id: 'b', title: 'Read');

    test('has no hour and an empty label', () {
      expect(task.isTimed, isFalse);
      expect(task.hour, isNull);
      expect(task.timeLabel, '');
    });

    test('cannot carry a bell — it would never ring', () {
      expect(const DayTask(id: 'b', title: 'Read', notify: true).notify, isTrue,
          reason: 'the constructor stays literal');
      // ...but the copy path enforces the rule.
      expect(task.copyWith(notify: true).notify, isFalse);
    });
  });

  group('copyWith', () {
    const timed =
        DayTask(id: 'c', title: 'Gym', atMinutes: 17 * 60, notify: true);

    test('toggling done keeps the time and the bell', () {
      final done = timed.toggle();
      expect(done.done, isTrue);
      expect(done.atMinutes, 17 * 60);
      expect(done.notify, isTrue);
    });

    test('clearing the time drops the bell with it', () {
      final loose = timed.copyWith(clearTime: true);
      expect(loose.atMinutes, isNull);
      expect(loose.notify, isFalse);
    });
  });

  group('persistence', () {
    test('round-trips a timed task', () {
      const task = DayTask(
        id: 'd',
        title: 'Lunch',
        done: true,
        atMinutes: 13 * 60 + 30,
        notify: true,
      );
      expect(DayTask.fromJson(task.toJson()), task);
    });

    test('reads tasks saved before times existed', () {
      final old = DayTask.fromJson(
          const {'id': 'e', 'title': 'Old task', 'done': false});
      expect(old.atMinutes, isNull);
      expect(old.notify, isFalse);
      expect(old.title, 'Old task');
    });
  });
}

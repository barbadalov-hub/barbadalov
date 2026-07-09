import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/reminders/domain/entities/reminder.dart';
import 'package:lifeos/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

void main() {
  test('Reminder JSON round-trips and derives a stable positive id', () {
    const r = Reminder(
      id: 'abc',
      kind: ReminderKind.water,
      hour: 9,
      minute: 30,
    );
    final back = Reminder.fromJson(r.toJson());
    expect(back, r);
    expect(back.notificationId, greaterThanOrEqualTo(0));
    expect(back.timeLabel, '09:30');
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore()),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('add / toggle / remove mutate state and persist across a reload', () {
    final store = InMemoryKeyValueStore();
    final c = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);

    final ctrl = c.read(remindersProvider.notifier);
    expect(c.read(remindersProvider), isEmpty);

    ctrl.add(kind: ReminderKind.workout, hour: 18, minute: 0);
    expect(c.read(remindersProvider).single.kind, ReminderKind.workout);

    final id = c.read(remindersProvider).single.id;
    ctrl.toggle(id);
    expect(c.read(remindersProvider).single.enabled, isFalse);

    // A fresh container reading the same store hydrates the saved reminder.
    final c2 = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c2.dispose);
    expect(c2.read(remindersProvider).single.id, id);
    expect(c2.read(remindersProvider).single.enabled, isFalse);

    ctrl.remove(id);
    expect(c.read(remindersProvider), isEmpty);
  });

  test('quick-add uses each kind default time', () {
    final c = makeContainer();
    final ctrl = c.read(remindersProvider.notifier);
    ctrl.add(
      kind: ReminderKind.sleep,
      hour: ReminderKind.sleep.defaultHour,
      minute: ReminderKind.sleep.defaultMinute,
    );
    final r = c.read(remindersProvider).single;
    expect(r.timeLabel, '22:30');
  });
}

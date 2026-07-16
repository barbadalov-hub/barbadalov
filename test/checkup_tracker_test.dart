import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/profile/domain/checkup_advisor.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

void main() {
  ProviderContainer containerWith(InMemoryKeyValueStore store) =>
      ProviderContainer(
          overrides: [keyValueStoreProvider.overrideWithValue(store)]);

  test('cycle advances todo → planned → done → todo', () {
    final c = containerWith(InMemoryKeyValueStore());
    addTearDown(c.dispose);
    final notifier = c.read(checkupTrackerProvider.notifier);

    expect(notifier.statusOf('doctor.gp'), CheckupStatus.todo);
    notifier.cycle('doctor.gp');
    expect(notifier.statusOf('doctor.gp'), CheckupStatus.planned);
    notifier.cycle('doctor.gp');
    expect(notifier.statusOf('doctor.gp'), CheckupStatus.done);
    notifier.cycle('doctor.gp');
    expect(notifier.statusOf('doctor.gp'), CheckupStatus.todo);
  });

  test('status persists across a rebuilt container', () {
    final store = InMemoryKeyValueStore();
    final c1 = containerWith(store);
    c1.read(checkupTrackerProvider.notifier).cycle('lab.vitd'); // planned
    c1.read(checkupTrackerProvider.notifier).cycle('lab.vitd'); // done
    c1.dispose();

    final c2 = containerWith(store);
    addTearDown(c2.dispose);
    expect(c2.read(checkupTrackerProvider)['lab.vitd'], CheckupStatus.done);
  });

  test('todo entries are not stored (kept sparse)', () {
    final store = InMemoryKeyValueStore();
    final c = containerWith(store);
    addTearDown(c.dispose);
    final n = c.read(checkupTrackerProvider.notifier);
    n.cycle('doctor.gp'); // planned
    n.cycle('doctor.gp'); // done
    n.cycle('doctor.gp'); // back to todo → removed
    expect(c.read(checkupTrackerProvider).containsKey('doctor.gp'), isFalse);
    expect(store.getString('checkup.status') ?? '', isEmpty);
  });

  test('trackKey is stable and kind-scoped', () {
    const doc = CheckupSuggestion(
        CheckupKind.doctor, 'cardiologist', 'checkup.reason.cardio');
    const lab =
        CheckupSuggestion(CheckupKind.lab, 'lipids', 'checkup.reason.cardio');
    expect(doc.trackKey, 'doctor.cardiologist');
    expect(lab.trackKey, 'lab.lipids');
  });
}

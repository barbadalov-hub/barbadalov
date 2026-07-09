import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/home/presentation/providers/today_layout_provider.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

void main() {
  ProviderContainer containerWith(InMemoryKeyValueStore store) =>
      ProviderContainer(
        overrides: [keyValueStoreProvider.overrideWithValue(store)],
      );

  test('everything is visible by default', () {
    final c = containerWith(InMemoryKeyValueStore({}));
    addTearDown(c.dispose);
    expect(c.read(todayHiddenProvider), isEmpty);
  });

  test('hiding and showing a section updates state and persists', () {
    final store = InMemoryKeyValueStore({});
    final c = containerWith(store);
    addTearDown(c.dispose);

    final ctrl = c.read(todayHiddenProvider.notifier);
    ctrl.setVisible('diet', false);
    ctrl.setVisible('quote', false);
    expect(c.read(todayHiddenProvider), {'diet', 'quote'});

    ctrl.setVisible('diet', true);
    expect(c.read(todayHiddenProvider), {'quote'});
    expect(store.getString('today.hidden'), 'quote');

    // A fresh container over the same store restores the hidden set.
    final c2 = containerWith(store);
    addTearDown(c2.dispose);
    expect(c2.read(todayHiddenProvider), {'quote'});
  });

  test('section catalog has unique ids', () {
    final ids = kTodaySections.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('default order matches the catalog', () {
    final c = containerWith(InMemoryKeyValueStore({}));
    addTearDown(c.dispose);
    expect(c.read(todayOrderProvider),
        kTodaySections.map((s) => s.id).toList());
  });

  test('reordering moves a section and persists', () {
    final store = InMemoryKeyValueStore({});
    final c = containerWith(store);
    addTearDown(c.dispose);

    final before = c.read(todayOrderProvider);
    // Move the last section to the front.
    c.read(todayOrderProvider.notifier).reorder(before.length - 1, 0);
    final after = c.read(todayOrderProvider);
    expect(after.first, before.last);
    expect(after.length, before.length);
    expect(store.getString('today.order'), after.join(','));

    // Restored from the same store.
    final c2 = containerWith(store);
    addTearDown(c2.dispose);
    expect(c2.read(todayOrderProvider).first, before.last);
  });

  group('focusLayout', () {
    final catalogIds = kTodaySections.map((s) => s.id).toSet();

    test('empty focus keeps the default layout', () {
      final l = focusLayout({});
      expect(l.hidden, isEmpty);
      expect(l.order, kTodaySections.map((s) => s.id).toList());
    });

    test('a single focus keeps core + its cards, hides the rest', () {
      final l = focusLayout({'money'});
      // Core always shown.
      expect(l.hidden.contains('quickActions'), isFalse);
      expect(l.hidden.contains('lifeScore'), isFalse);
      // Money cards shown.
      expect(l.hidden.contains('safeToSpend'), isFalse);
      expect(l.hidden.contains('budget'), isFalse);
      // Unrelated cards hidden.
      expect(l.hidden.contains('health'), isTrue);
      expect(l.hidden.contains('diet'), isTrue);
      // Order is a full permutation and starts with core.
      expect(l.order.toSet(), catalogIds);
      expect(l.order.take(2), containsAll(['quickActions', 'lifeScore']));
    });

    test('multiple focuses union their cards', () {
      final l = focusLayout({'health', 'food'});
      expect(l.hidden.contains('health'), isFalse);
      expect(l.hidden.contains('diet'), isFalse);
      expect(l.hidden.contains('budget'), isTrue);
      expect(l.order.toSet(), catalogIds);
    });
  });

  test('stored order is reconciled with the catalog', () {
    // A stale stored order: unknown id + missing several real ones.
    final store = InMemoryKeyValueStore({'today.order': 'ghost,achievements,diet'});
    final c = containerWith(store);
    addTearDown(c.dispose);

    final order = c.read(todayOrderProvider);
    final catalogIds = kTodaySections.map((s) => s.id).toSet();
    expect(order.contains('ghost'), isFalse); // unknown dropped
    expect(order.toSet(), catalogIds); // every real section present
    expect(order.take(2).toList(), ['achievements', 'diet']); // known order kept
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/food/domain/entities/food_item.dart';
import 'package:lifeos/features/food/domain/pantry_planner.dart';

final _now = DateTime(2026, 1, 10);

FoodItem _item(String name, {int? inDays}) => FoodItem(
      id: name,
      name: name,
      emoji: '',
      addedAt: _now,
      expiry: inDays == null ? null : _now.add(Duration(days: inDays)),
    );

void main() {
  group('PantryPlanner.byUrgency', () {
    test('orders dated items soonest-first, expired ahead of fresh', () {
      final items = [
        _item('Rice', inDays: null), // no expiry -> excluded
        _item('Bread', inDays: 5),
        _item('Milk', inDays: 1),
        _item('Ham', inDays: -2), // already expired
      ];
      final order = PantryPlanner.byUrgency(items, _now).map((i) => i.name);
      expect(order, ['Ham', 'Milk', 'Bread']);
    });

    test('breaks ties on name for a stable order', () {
      final order = PantryPlanner
          .byUrgency([_item('Pear', inDays: 2), _item('Apple', inDays: 2)], _now)
          .map((i) => i.name);
      expect(order, ['Apple', 'Pear']);
    });
  });

  group('PantryPlanner.useNext', () {
    test('picks the soonest-expiring item that is not spoiled', () {
      final next = PantryPlanner.useNext([
        _item('Ham', inDays: -1), // expired -> skip
        _item('Milk', inDays: 2),
        _item('Bread', inDays: 4),
      ], _now);
      expect(next?.name, 'Milk');
    });

    test('includes an item expiring today', () {
      final next = PantryPlanner.useNext([_item('Yogurt', inDays: 0)], _now);
      expect(next?.name, 'Yogurt');
    });

    test('is null when everything is undated or already expired', () {
      expect(
        PantryPlanner.useNext(
            [_item('Rice'), _item('Ham', inDays: -3)], _now),
        isNull,
      );
      expect(PantryPlanner.useNext(const [], _now), isNull);
    });
  });
}

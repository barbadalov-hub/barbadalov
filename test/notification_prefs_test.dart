import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/food/domain/entities/nutrition.dart';
import 'package:lifeos/features/food/presentation/providers/diet_providers.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_prefs.dart';

void main() {
  group('NotificationPrefs', () {
    test('categories default to enabled', () {
      const p = NotificationPrefs();
      expect(p.enabled('expiry'), isTrue);
      expect(p.enabled('anything'), isTrue);
    });

    test('quiet hours honour a wrap-around window', () {
      const off = NotificationPrefs(quietEnabled: false);
      expect(off.quietAt(23), isFalse);

      const night =
          NotificationPrefs(quietEnabled: true, quietStart: 22, quietEnd: 7);
      expect(night.quietAt(23), isTrue);
      expect(night.quietAt(6), isTrue);
      expect(night.quietAt(7), isFalse);
      expect(night.quietAt(12), isFalse);

      const day =
          NotificationPrefs(quietEnabled: true, quietStart: 1, quietEnd: 5);
      expect(day.quietAt(3), isTrue);
      expect(day.quietAt(6), isFalse);
    });

    test('JSON round-trips categories and quiet hours', () {
      const p = NotificationPrefs(
        categories: {'expiry': false, 'budget': true},
        quietEnabled: true,
        quietStart: 21,
        quietEnd: 8,
      );
      final back = NotificationPrefs.fromJson(p.toJson());
      expect(back.enabled('expiry'), isFalse);
      expect(back.enabled('budget'), isTrue);
      expect(back.quietStart, 21);
      expect(back.quietEnd, 8);
    });
  });

  test('ManualFoodEntry JSON round-trips its nutrition', () {
    const e = ManualFoodEntry(
      id: 'a',
      name: 'Banana',
      nutrition: NutritionFacts(kcal: 105, proteinG: 1, fatG: 0, carbsG: 27),
    );
    final back = ManualFoodEntry.fromJson(e.toJson());
    expect(back.name, 'Banana');
    expect(back.nutrition.kcal, 105);
    expect(back.nutrition.carbsG, 27);
  });
}

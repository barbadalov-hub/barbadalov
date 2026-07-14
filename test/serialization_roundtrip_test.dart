import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/food/domain/entities/food_item.dart';
import 'package:lifeos/features/food/domain/entities/meal_plan.dart';
import 'package:lifeos/features/food/domain/entities/shopping_item.dart';
import 'package:lifeos/features/goals/domain/entities/goal.dart';
import 'package:lifeos/features/health/domain/entities/health_day.dart';
import 'package:lifeos/features/health/domain/entities/measurement.dart';
import 'package:lifeos/features/mind/domain/entities/book.dart';
import 'package:lifeos/features/mind/domain/entities/day_task.dart';
import 'package:lifeos/features/mind/domain/entities/habit.dart';
import 'package:lifeos/features/mind/domain/mood.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/features/wellness/domain/cycle_log.dart';
import 'package:lifeos/shared/models/money.dart';

/// Persistence goes through jsonEncode → localStorage/file → jsonDecode. This
/// runs each entity's toJson through that exact trip and back, asserting no
/// field is dropped or re-typed — the silent-data-loss guard the app relies on.
Map<String, dynamic> _trip(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

final _d = DateTime(2026, 3, 4, 9, 30, 15);

void main() {
  test('Transaction round-trips', () {
    final x = Transaction(
      id: 't1',
      amount: const Money(12345, currency: 'UAH'),
      type: TransactionType.expense,
      categoryId: DefaultCategories.food.id,
      date: _d,
      note: 'lunch',
    );
    expect(Transaction.fromJson(_trip(x.toJson())).toJson(), x.toJson());
  });

  test('Goal (with milestones + target date + currency) round-trips', () {
    final x = Goal(
      id: 'g1',
      title: 'New bike',
      emoji: '🚲',
      target: const Money(500000, currency: 'UAH'),
      saved: const Money(125000, currency: 'UAH'),
      targetDate: _d,
      milestones: const [
        Milestone(title: 'Pick model', done: true),
        Milestone(title: 'Save half'),
      ],
    );
    expect(Goal.fromJson(_trip(x.toJson())).toJson(), x.toJson());
  });

  test('FoodItem (with expiry) round-trips', () {
    final x = FoodItem(
      id: 'f1',
      name: 'Milk',
      emoji: '🥛',
      addedAt: _d,
      quantity: 2,
      expiry: _d.add(const Duration(days: 3)),
    );
    expect(FoodItem.fromJson(_trip(x.toJson())).toJson(), x.toJson());
  });

  test('ShoppingItem round-trips', () {
    const x = ShoppingItem(id: 's1', name: 'Eggs', checked: true);
    expect(ShoppingItem.fromJson(_trip(x.toJson())).toJson(), x.toJson());
  });

  test('HealthDay (all optional fields set) round-trips', () {
    final x = HealthDay(
      date: _d,
      steps: 8421,
      waterMl: 6 * 250,
      sleepHours: 7.5,
      weightKg: 72.3,
      stress: 3,
      heartRate: 58,
      listeningMinutes: 45,
    );
    expect(HealthDay.fromJson(_trip(x.toJson())).toJson(), x.toJson());
  });

  test('Habit (with completion history) round-trips', () {
    final x = Habit(
      id: 'h1',
      name: 'Read',
      emoji: '📚',
      doneToday: true,
      streak: 4,
      completedDates: [_d, _d.subtract(const Duration(days: 1))],
      targetPerWeek: 5,
    );
    expect(Habit.fromJson(_trip(x.toJson())).toJson(), x.toJson());
  });

  test('DayTask round-trips', () {
    const x = DayTask(id: 'd1', title: 'Plan week', done: true);
    expect(DayTask.fromJson(_trip(x.toJson())).toJson(), x.toJson());
  });

  test('Book round-trips', () {
    const x = Book(
      id: 'b1',
      title: 'Deep Work',
      author: 'Cal Newport',
      totalPages: 296,
      currentPage: 120,
    );
    expect(Book.fromJson(_trip(x.toJson())).toJson(), x.toJson());
  });

  test('CycleDayLog (flow + symptoms + note) round-trips', () {
    final x = CycleDayLog(
      date: _d,
      flow: 2,
      symptoms: const ['cramps', 'fatigue'],
      note: 'rest day',
    );
    expect(CycleDayLog.fromJson(_trip(x.toJson())).toJson(), x.toJson());
  });

  test('MealPlan (int weekday keys) round-trips', () {
    const x = MealPlan(meals: {1: 'Oats', 3: 'Soup', 7: 'Roast'});
    expect(MealPlan.fromJson(_trip(x.toJson())).toJson(), x.toJson());
  });

  test('MeasurementEntry (enum field) round-trips', () {
    final x = MeasurementEntry(date: _d, field: MeasurementField.hips, cm: 96.5);
    expect(MeasurementEntry.fromJson(_trip(x.toJson())).toJson(), x.toJson());
  });

  test('MoodEntry (activities + note) round-trips', () {
    final x = MoodEntry(
      date: _d,
      mood: 4,
      activities: const ['sport', 'friends'],
      note: 'good day',
    );
    expect(MoodEntry.fromJson(_trip(x.toJson())).toJson(), x.toJson());
  });
}

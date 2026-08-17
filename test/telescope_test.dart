import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/health/domain/entities/health_day.dart';
import 'package:lifeos/features/mind/domain/mood.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/features/telescope/domain/period_stats.dart';
import 'package:lifeos/shared/models/money.dart';

Transaction _tx(String date, int minor, {bool expense = true, String? cat}) =>
    Transaction(
      id: '$date-$minor',
      amount: Money(minor),
      type: expense ? TransactionType.expense : TransactionType.income,
      categoryId: cat ?? (expense ? 'expense_food' : 'income_salary'),
      date: DateTime.parse(date),
    );

/// [water] is in glasses, converted to the millilitres the entity stores.
HealthDay _day(String date, {int steps = 0, double sleep = 0, int water = 0}) =>
    HealthDay(
      date: DateTime.parse(date),
      steps: steps,
      sleepHours: sleep,
      waterMl: water * HealthDay.mlPerGlass,
    );

MoodEntry _mood(String date, int mood) =>
    MoodEntry(date: DateTime.parse(date), mood: mood);

void main() {
  const builder = PeriodStatsBuilder();
  final now = DateTime(2026, 3, 10, 15);

  group('zoom windows', () {
    test('day counts include today and exclude the day before the window', () {
      expect(TimeZoom.d3.days, 3);
      expect(TimeZoom.d7.days, 7);
      expect(TimeZoom.d30.days, 30);
      expect(TimeZoom.all.days, isNull, reason: 'all-time has no window');
    });

    test('a 3-day window covers today and the two days before it', () {
      final stats = builder.build(
        zoom: TimeZoom.d3,
        now: now,
        transactions: [
          _tx('2026-03-10', 100), // today
          _tx('2026-03-08', 200), // first day in window
          _tx('2026-03-07', 400), // just outside
        ],
        days: const [],
        moods: const [],
      );
      expect(stats.spentMinor, 300);
    });

    test('all-time takes everything up to today but nothing in the future', () {
      final stats = builder.build(
        zoom: TimeZoom.all,
        now: now,
        transactions: [
          _tx('2020-01-01', 500),
          _tx('2026-03-10', 100),
          _tx('2026-04-01', 900), // a future-dated entry must not count
        ],
        days: const [],
        moods: const [],
      );
      expect(stats.spentMinor, 600);
    });
  });

  group('aggregation', () {
    test('separates income from spending and picks the top category', () {
      final stats = builder.build(
        zoom: TimeZoom.d7,
        now: now,
        transactions: [
          _tx('2026-03-10', 500, cat: 'expense_food'),
          _tx('2026-03-09', 300, cat: 'expense_food'),
          _tx('2026-03-09', 700, cat: 'expense_fun'),
          _tx('2026-03-08', 2000, expense: false),
        ],
        days: const [],
        moods: const [],
      );
      expect(stats.spentMinor, 1500);
      expect(stats.incomeMinor, 2000);
      expect(stats.netMinor, 500);
      expect(stats.topCategoryId, 'expense_food',
          reason: 'food totals 800 vs fun 700');
    });

    test('averages skip days that logged nothing for that metric', () {
      final stats = builder.build(
        zoom: TimeZoom.d7,
        now: now,
        transactions: const [],
        days: [
          _day('2026-03-10', steps: 10000, sleep: 8),
          _day('2026-03-09', steps: 6000), // no sleep logged
          _day('2026-03-08', water: 5), // no steps, no sleep
        ],
        moods: const [],
      );
      // Sleep averages over the one day that has it, not over three.
      expect(stats.avgSleep, 8);
      expect(stats.avgSteps, 8000);
      expect(stats.totalSteps, 16000);
      expect(stats.peakSteps, 10000);
      expect(stats.avgWater, 5);
    });

    test('counts a day once no matter how many logs it holds', () {
      final stats = builder.build(
        zoom: TimeZoom.d7,
        now: now,
        transactions: [_tx('2026-03-10', 100), _tx('2026-03-10', 200)],
        days: [_day('2026-03-10', steps: 500)],
        moods: [_mood('2026-03-10', 4)],
      );
      expect(stats.daysTracked, 1);
      expect(stats.moodDays, 1);
      expect(stats.avgMood, 4);
    });

    test('an empty window has no data and never divides by zero', () {
      final stats = builder.build(
        zoom: TimeZoom.d3,
        now: now,
        transactions: const [],
        days: const [],
        moods: const [],
      );
      expect(stats.hasData, isFalse);
      expect(stats.avgSleep, 0);
      expect(stats.avgMood, 0);
      expect(stats.avgSteps, 0);
      expect(stats.daysTracked, 0);
    });
  });
}

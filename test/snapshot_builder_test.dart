import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/health/domain/entities/health_day.dart';
import 'package:lifeos/features/history/application/snapshot_builder.dart';
import 'package:lifeos/features/mind/domain/mood.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/shared/models/money.dart';

void main() {
  const builder = SnapshotBuilder();

  Transaction tx(int day, int major, TransactionType type, Category c) =>
      Transaction(
        id: 'id$day$major',
        amount: Money.fromMajor(major),
        type: type,
        categoryId: c.id,
        date: DateTime(2026, 7, day),
      );

  test('aggregates a month across pillars', () {
    final snap = builder.build(
      ym: 202607,
      transactions: [
        tx(1, 3000, TransactionType.income, DefaultCategories.salary),
        tx(3, 200, TransactionType.expense, DefaultCategories.food),
        tx(5, 120, TransactionType.expense, DefaultCategories.fun),
        tx(9, 800, TransactionType.income, DefaultCategories.salary), // wrong mo? no, July
        tx(2, 50, TransactionType.expense, DefaultCategories.food),
        // A different month is ignored:
        Transaction(
          id: 'other',
          amount: Money.fromMajor(999),
          type: TransactionType.expense,
          categoryId: DefaultCategories.home.id,
          date: DateTime(2026, 6, 1),
        ),
      ],
      moods: [
        MoodEntry(date: DateTime(2026, 7, 4), mood: 4),
        MoodEntry(date: DateTime(2026, 7, 5), mood: 2),
        MoodEntry(date: DateTime(2026, 6, 5), mood: 5), // other month
      ],
      days: [
        HealthDay(
            date: DateTime(2026, 7, 2),
            steps: 8000,
            waterMl: 6 * 250,
            sleepHours: 7),
        HealthDay(
            date: DateTime(2026, 7, 6),
            steps: 12000,
            waterMl: 8 * 250,
            sleepHours: 8),
      ],
      weights: [
        (DateTime(2026, 5, 1), 80.0),
        (DateTime(2026, 7, 10), 78.5),
        (DateTime(2026, 8, 1), 77.0), // future month ignored
      ],
    );

    expect(snap.incomeMinor, Money.fromMajor(3800).minorUnits);
    expect(snap.spentMinor, Money.fromMajor(370).minorUnits); // 200+120+50
    expect(snap.topCategoryId, DefaultCategories.food.id); // 250 > fun 120
    expect(snap.avgMood, 3.0); // (4+2)/2
    expect(snap.avgSteps, 10000); // (8000+12000)/2
    expect(snap.weightKg, 78.5); // last in/at July
    expect(snap.hasData, isTrue);
  });

  test('an empty month has no data', () {
    final snap = builder.build(
      ym: 202601,
      transactions: const [],
      moods: const [],
      days: const [],
      weights: const [],
    );
    expect(snap.hasData, isFalse);
  });
}

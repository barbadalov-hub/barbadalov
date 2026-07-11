import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/services/life_score_service.dart';
import 'package:lifeos/features/money/domain/entities/budget.dart';
import 'package:lifeos/shared/models/money.dart';

/// Builds a Budget with just the fields the finance pillar reads.
Budget _budget({
  required int incomeMinor,
  required int reserveMinor,
  required int expenseMinor,
}) {
  final available =
      Money(incomeMinor - reserveMinor - expenseMinor).clampToZero();
  return Budget(
    income: Money(incomeMinor),
    expenses: Money(expenseMinor),
    reserve: Money(reserveMinor),
    reserveRate: 0.15,
    available: available,
    safeToSpendToday: const Money.zero(),
    remainingDays: 10,
  );
}

void main() {
  const service = LifeScoreService();

  group('LifeScoreService', () {
    test('no income and no pillar data is a neutral 50 across the board', () {
      final s = service.compute(budget: Budget.empty());
      expect(s.finance, 50);
      expect(s.health, 50);
      expect(s.discipline, 50);
      expect(s.productivity, 50);
      expect(s.total, 50);
    });

    test('a fully unspent budget scores the finance pillar at 100', () {
      final s = service.compute(
        budget: _budget(incomeMinor: 100000, reserveMinor: 15000, expenseMinor: 0),
      );
      expect(s.finance, 100);
      // 100*.30 + 50*.30 + 50*.20 + 50*.20 = 65
      expect(s.total, 65);
    });

    test('overspending drops the finance pillar to 15', () {
      final s = service.compute(
        budget:
            _budget(incomeMinor: 100000, reserveMinor: 15000, expenseMinor: 90000),
      );
      expect(s.finance, 15);
      // 15*.30 + 50*.30 + 50*.20 + 50*.20 = 39.5 -> 40
      expect(s.total, 40);
    });

    test('blends all four pillars by their configured weights', () {
      final s = service.compute(
        budget: _budget(incomeMinor: 100000, reserveMinor: 15000, expenseMinor: 0),
        healthScore: 80,
        disciplineScore: 90,
        productivityScore: 70,
      );
      // 100*.30 + 80*.30 + 90*.20 + 70*.20 = 86
      expect(s.total, 86);
      expect(s.health, 80);
      expect(s.discipline, 90);
      expect(s.productivity, 70);
    });

    test('the finance pillar tracks the share of spendable budget left', () {
      // available 42500 of 85000 spendable -> 50.
      final s = service.compute(
        budget:
            _budget(incomeMinor: 100000, reserveMinor: 15000, expenseMinor: 42500),
      );
      expect(s.finance, 50);
    });
  });
}

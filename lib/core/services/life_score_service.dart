import 'package:equatable/equatable.dart';
import 'package:lifeos/core/constants/app_constants.dart';
import 'package:lifeos/features/money/domain/entities/budget.dart';

/// The 0–100 Life Score and its four pillars.
class LifeScore extends Equatable {
  final int total;
  final int finance;
  final int health;
  final int discipline;
  final int productivity;

  const LifeScore({
    required this.total,
    required this.finance,
    required this.health,
    required this.discipline,
    required this.productivity,
  });

  @override
  List<Object?> get props => [total, finance, discipline, health, productivity];
}

/// Computes the composite Life Score. In Phase 1 only the **finance** pillar has
/// real data (from MoneyOS); health/discipline/productivity default to a neutral
/// 50 until HealthOS and MindOS come online, so the score is honest about what
/// it does and doesn't yet know.
class LifeScoreService {
  const LifeScoreService();

  LifeScore compute({
    required Budget budget,
    int? healthScore,
    int? disciplineScore,
    int? productivityScore,
  }) {
    final finance = _financeScore(budget);
    final health = healthScore ?? 50;
    final discipline = disciplineScore ?? 50;
    final productivity = productivityScore ?? 50;

    final total = (finance * AppConstants.financeWeight +
            health * AppConstants.healthWeight +
            discipline * AppConstants.disciplineWeight +
            productivity * AppConstants.productivityWeight)
        .round();

    return LifeScore(
      total: total.clamp(0, 100).toInt(),
      finance: finance,
      health: health,
      discipline: discipline,
      productivity: productivity,
    );
  }

  int _financeScore(Budget budget) {
    if (budget.income.isZero) return 50; // no data → neutral
    if (budget.isOverspent) return 15;

    final spendable = budget.income.minorUnits - budget.reserve.minorUnits;
    if (spendable <= 0) return 50;

    // Higher share of spendable budget still available ⇒ healthier finances.
    final ratio = budget.available.minorUnits / spendable;
    return (ratio * 100).round().clamp(0, 100).toInt();
  }
}

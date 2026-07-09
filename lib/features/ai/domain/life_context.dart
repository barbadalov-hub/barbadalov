import 'package:equatable/equatable.dart';

/// A decoupled, primitive snapshot of the user's life that the AI reasons over.
/// Built from every module's *current state* but deliberately holds no feature
/// types, so the AI engine depends on nothing feature-specific.
class LifeContext extends Equatable {
  final int safeToSpendTodayMinor;
  final String currency;
  final bool overspent;
  final int reserveRatePct;
  final int healthScore;
  final int disciplineScore;
  final int productivityScore;
  final List<String> expiringFoods;

  /// Dietitian data: daily calorie target (null until a profile exists) and
  /// calories already eaten today.
  final int? kcalTarget;
  final int kcalEaten;

  const LifeContext({
    required this.safeToSpendTodayMinor,
    required this.currency,
    required this.overspent,
    required this.reserveRatePct,
    required this.healthScore,
    required this.disciplineScore,
    required this.productivityScore,
    required this.expiringFoods,
    this.kcalTarget,
    this.kcalEaten = 0,
  });

  @override
  List<Object?> get props => [
        safeToSpendTodayMinor,
        currency,
        overspent,
        reserveRatePct,
        healthScore,
        disciplineScore,
        productivityScore,
        expiringFoods,
        kcalTarget,
        kcalEaten,
      ];
}

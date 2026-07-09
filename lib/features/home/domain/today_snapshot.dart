import 'package:equatable/equatable.dart';
import 'package:lifeos/core/services/life_score_service.dart';
import 'package:lifeos/features/money/domain/entities/budget.dart';

/// Everything the Today screen needs, assembled from every module. Phase 1 fills
/// the money + life-score parts with real data and marks the rest as pending so
/// the screen honestly reflects which systems are online.
class TodaySnapshot extends Equatable {
  final Budget budget;
  final LifeScore lifeScore;
  final List<ModuleTeaser> pendingModules;

  const TodaySnapshot({
    required this.budget,
    required this.lifeScore,
    required this.pendingModules,
  });

  @override
  List<Object?> get props => [budget, lifeScore, pendingModules];
}

/// A placeholder card for a module that ships in a later phase.
class ModuleTeaser extends Equatable {
  final String emoji;
  final String title;
  final String subtitle;

  const ModuleTeaser({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  List<Object?> get props => [emoji, title, subtitle];
}

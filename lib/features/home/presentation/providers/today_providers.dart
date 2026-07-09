import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/services/life_score_service.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/features/home/domain/today_snapshot.dart';
import 'package:lifeos/features/mind/presentation/providers/mind_providers.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// The composite Life Score, now derived from **all four pillars** with real
/// data: finance (MoneyOS), health (HealthOS), discipline & productivity
/// (MindOS).
final lifeScoreProvider = Provider<LifeScore>((ref) {
  return ref.watch(lifeScoreServiceProvider).compute(
        budget: ref.watch(currentBudgetProvider),
        healthScore: ref.watch(healthScoreProvider),
        disciplineScore: ref.watch(disciplineScoreProvider),
        productivityScore: ref.watch(productivityScoreProvider),
      );
});

/// The single source the Today screen watches. With every module online there
/// are no "coming soon" teasers left.
final todaySnapshotProvider = Provider<TodaySnapshot>((ref) {
  return TodaySnapshot(
    budget: ref.watch(currentBudgetProvider),
    lifeScore: ref.watch(lifeScoreProvider),
    pendingModules: const [],
  );
});

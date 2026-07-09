import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/ai/application/ai_event_handler.dart';
import 'package:lifeos/features/ai/data/ai_insight_store.dart';
import 'package:lifeos/features/ai/domain/ai_engine.dart';
import 'package:lifeos/features/ai/domain/ai_insight.dart';
import 'package:lifeos/features/ai/domain/life_context.dart';
import 'package:lifeos/features/food/presentation/providers/diet_providers.dart';
import 'package:lifeos/features/food/presentation/providers/food_providers.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/features/mind/presentation/providers/mind_providers.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

final aiEngineProvider = Provider<AiEngine>(
    (ref) => RuleBasedAiEngine(ref.watch(idServiceProvider)));

final aiInsightStoreProvider = Provider<AiInsightStore>((ref) {
  final store = AiInsightStore();
  ref.onDispose(store.dispose);
  return store;
});

/// Builds the primitive [LifeContext] from every module's *current* state,
/// reading data sources/repositories directly (never the engine-dependent
/// stream providers) so this can run inside an engine handler without a cycle.
LifeContext buildLifeContext(Ref ref) {
  final now = ref.read(clockProvider).now();

  // Money → budget.
  final tx = ref.read(moneyLocalDataSourceProvider).all();
  final monthTx = tx
      .where((t) => t.date.year == now.year && t.date.month == now.month)
      .toList(growable: false);
  final budget = ref.read(computeBudgetProvider).call(monthTx, at: now);

  // Health.
  final day = ref.read(healthRepositoryProvider).today();
  final healthScore = ref.read(healthScoreServiceProvider).scoreFor(day);

  // Mind → discipline / productivity.
  final habits = ref.read(mindRepositoryProvider).habits();
  final tasks = ref.read(mindRepositoryProvider).tasks();
  final discipline = habits.isEmpty
      ? 50
      : (habits.where((h) => h.doneToday).length / habits.length * 100).round();
  final productivity = tasks.isEmpty
      ? 50
      : (tasks.where((t) => t.done).length / tasks.length * 100).round();

  // Food → expiring names.
  final expiring = ref
      .read(foodRepositoryProvider)
      .pantry()
      .where((f) => f.isExpiringSoon(now) || f.isExpired(now))
      .map((f) => f.name)
      .toList();

  // Dietitian → today's calorie target vs eaten.
  final assessment = ref.read(assessmentProvider);
  final eaten = ref.read(consumedNutritionProvider);

  return LifeContext(
    safeToSpendTodayMinor: budget.safeToSpendToday.minorUnits,
    currency: budget.safeToSpendToday.currency,
    overspent: budget.isOverspent,
    reserveRatePct: (budget.reserveRate * 100).round(),
    healthScore: healthScore,
    disciplineScore: discipline,
    productivityScore: productivity,
    expiringFoods: expiring,
    kcalTarget: assessment?.targetKcal,
    kcalEaten: eaten.kcal,
  );
}

/// A ready-to-register handler. Also exposes `analyzeNow()` for bootstrap.
final aiEventHandlerProvider = Provider<AiEventHandler>((ref) {
  return AiEventHandler(
    engine: ref.watch(aiEngineProvider),
    store: ref.watch(aiInsightStoreProvider),
    buildContext: () => buildLifeContext(ref),
  );
});

/// Live insights for the AI screen and the Today card. Touching
/// [coreEngineProvider] guarantees the handler is registered and has run once.
final aiInsightsProvider = StreamProvider<List<AiInsight>>((ref) {
  ref.watch(coreEngineProvider);
  return ref.watch(aiInsightStoreProvider).watch();
});

/// The single headline insight for the Today screen (prefers a finance one).
final headlineInsightProvider = Provider<AiInsight?>((ref) {
  final list = ref.watch(aiInsightsProvider).valueOrNull ?? const [];
  if (list.isEmpty) return null;
  return list.firstWhere(
    (i) => i.category == InsightCategory.finance,
    orElse: () => list.first,
  );
});

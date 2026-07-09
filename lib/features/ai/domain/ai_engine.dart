import 'package:lifeos/core/services/id_service.dart';
import 'package:lifeos/features/ai/domain/ai_insight.dart';
import 'package:lifeos/features/ai/domain/life_context.dart';
import 'package:lifeos/shared/models/money.dart';

/// The AI Engine contract. Phase 9 ships a deterministic, rule-based engine so
/// insights work offline and are testable. To use a real model, implement this
/// interface with a backend-proxied Claude call (e.g. `claude-opus-4-8`) and
/// swap `aiEngineProvider` — the handler, store and UI are unchanged. **Never
/// call a model with a secret key directly from the client.**
///
/// Insights carry i18n keys + params (see [AiInsight]) so generated guidance is
/// rendered in the user's language.
abstract class AiEngine {
  List<AiInsight> analyze(LifeContext context);
}

class RuleBasedAiEngine implements AiEngine {
  final IdService _idService;
  const RuleBasedAiEngine(this._idService);

  @override
  List<AiInsight> analyze(LifeContext ctx) {
    final insights = <AiInsight>[];

    // --- Finance ---------------------------------------------------------
    if (ctx.overspent) {
      insights.add(_i(
        InsightCategory.finance,
        '🛑',
        'aiMsg.pause.title',
        'aiMsg.pause.msg',
      ));
    } else {
      final safe = Money(ctx.safeToSpendTodayMinor, currency: ctx.currency);
      insights.add(_i(
        InsightCategory.finance,
        '💸',
        'aiMsg.target.title',
        'aiMsg.target.msg',
        {'amount': safe.format(), 'rate': ctx.reserveRatePct},
      ));
    }

    // --- Dietitian ---------------------------------------------------------
    final target = ctx.kcalTarget;
    if (target != null && ctx.kcalEaten > target * 1.05) {
      insights.add(_i(
        InsightCategory.food,
        '🍽️',
        'aiMsg.kcalOver.title',
        'aiMsg.kcalOver.msg',
        {'over': ctx.kcalEaten - target},
      ));
    }

    // --- Food ------------------------------------------------------------
    if (ctx.expiringFoods.isNotEmpty) {
      insights.add(_i(
        InsightCategory.food,
        '🥗',
        'aiMsg.food.title',
        'aiMsg.food.msg',
        {'items': ctx.expiringFoods.take(3).join(', ')},
      ));
    }

    // --- Health ----------------------------------------------------------
    if (ctx.healthScore < 60) {
      insights.add(_i(
        InsightCategory.health,
        '❤️',
        'aiMsg.health.title',
        'aiMsg.health.msg',
        {'score': ctx.healthScore},
      ));
    }

    // --- Discipline ------------------------------------------------------
    if (ctx.disciplineScore >= 80) {
      insights.add(_i(
        InsightCategory.discipline,
        '🔥',
        'aiMsg.disciplineHigh.title',
        'aiMsg.disciplineHigh.msg',
        {'pct': ctx.disciplineScore},
      ));
    } else if (ctx.disciplineScore < 40) {
      insights.add(_i(
        InsightCategory.discipline,
        '📈',
        'aiMsg.disciplineLow.title',
        'aiMsg.disciplineLow.msg',
        {'pct': ctx.disciplineScore},
      ));
    }

    if (insights.isEmpty) {
      insights.add(_i(
        InsightCategory.general,
        '✅',
        'aiMsg.balanced.title',
        'aiMsg.balanced.msg',
      ));
    }
    return insights;
  }

  AiInsight _i(
    InsightCategory category,
    String emoji,
    String titleKey,
    String messageKey, [
    Map<String, Object> params = const {},
  ]) =>
      AiInsight(
        id: _idService.newId(),
        category: category,
        emoji: emoji,
        titleKey: titleKey,
        messageKey: messageKey,
        params: params,
      );
}

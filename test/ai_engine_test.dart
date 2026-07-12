import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/ai/domain/ai_engine.dart';
import 'package:lifeos/features/ai/domain/ai_insight.dart';
import 'package:lifeos/features/ai/domain/life_context.dart';
import 'package:lifeos/core/services/id_service.dart';

class _SeqIds implements IdService {
  int _n = 0;
  @override
  String newId() => 'id${_n++}';
}

LifeContext _ctx({
  int safe = 5000,
  bool overspent = false,
  int reservePct = 15,
  int health = 80,
  int discipline = 60,
  int productivity = 60,
  List<String> expiring = const [],
  int? kcalTarget,
  int kcalEaten = 0,
}) =>
    LifeContext(
      safeToSpendTodayMinor: safe,
      currency: 'USD',
      overspent: overspent,
      reserveRatePct: reservePct,
      healthScore: health,
      disciplineScore: discipline,
      productivityScore: productivity,
      expiringFoods: expiring,
      kcalTarget: kcalTarget,
      kcalEaten: kcalEaten,
    );

void main() {
  late RuleBasedAiEngine engine;
  setUp(() => engine = RuleBasedAiEngine(_SeqIds()));

  Set<String> keys(List<AiInsight> xs) => xs.map((i) => i.titleKey).toSet();

  group('RuleBasedAiEngine', () {
    test('always emits exactly one finance insight — target when solvent', () {
      final xs = engine.analyze(_ctx());
      final finance =
          xs.where((i) => i.category == InsightCategory.finance).toList();
      expect(finance, hasLength(1));
      expect(finance.single.titleKey, 'aiMsg.target.title');
      expect(finance.single.params['rate'], 15);
    });

    test('overspending swaps the finance insight for a pause', () {
      final xs = engine.analyze(_ctx(overspent: true));
      expect(keys(xs), contains('aiMsg.pause.title'));
      expect(keys(xs), isNot(contains('aiMsg.target.title')));
    });

    test('eating over 105% of the calorie target warns', () {
      final xs = engine.analyze(_ctx(kcalTarget: 2000, kcalEaten: 2200));
      final food = xs.firstWhere((i) => i.titleKey == 'aiMsg.kcalOver.title');
      expect(food.params['over'], 200);
    });

    test('a small calorie overshoot within 5% does not warn', () {
      final xs = engine.analyze(_ctx(kcalTarget: 2000, kcalEaten: 2050));
      expect(keys(xs), isNot(contains('aiMsg.kcalOver.title')));
    });

    test('expiring foods surface up to three items', () {
      final xs = engine.analyze(
          _ctx(expiring: ['Milk', 'Eggs', 'Bread', 'Cheese']));
      final food = xs.firstWhere((i) => i.titleKey == 'aiMsg.food.title');
      expect(food.params['items'], 'Milk, Eggs, Bread');
    });

    test('a low health score nudges', () {
      expect(keys(engine.analyze(_ctx(health: 59))),
          contains('aiMsg.health.title'));
      expect(keys(engine.analyze(_ctx(health: 60))),
          isNot(contains('aiMsg.health.title')));
    });

    test('discipline praises high and nudges low', () {
      expect(keys(engine.analyze(_ctx(discipline: 80))),
          contains('aiMsg.disciplineHigh.title'));
      expect(keys(engine.analyze(_ctx(discipline: 39))),
          contains('aiMsg.disciplineLow.title'));
      // Mid band: neither.
      final mid = keys(engine.analyze(_ctx(discipline: 60)));
      expect(mid, isNot(contains('aiMsg.disciplineHigh.title')));
      expect(mid, isNot(contains('aiMsg.disciplineLow.title')));
    });

    test('every insight gets a unique id from the id service', () {
      final xs = engine.analyze(_ctx(
        health: 50,
        discipline: 90,
        kcalTarget: 2000,
        kcalEaten: 3000,
        expiring: ['Milk'],
      ));
      final ids = xs.map((i) => i.id).toSet();
      expect(ids, hasLength(xs.length));
    });
  });
}

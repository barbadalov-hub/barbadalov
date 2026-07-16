import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/insights/domain/cross_insights.dart';

DayMetrics _d({double? sleep, double? steps, double? water, double? spend}) =>
    DayMetrics({
      if (sleep != null) LifeMetric.sleep: sleep,
      if (steps != null) LifeMetric.steps: steps,
      if (water != null) LifeMetric.water: water,
      if (spend != null) LifeMetric.spend: spend,
    });

void main() {
  const engine = CrossInsightEngine();

  test('needs a minimum number of paired days', () {
    final days = [
      for (var i = 0; i < 4; i++) _d(sleep: 5 + i.toDouble(), spend: 100 - i * 10.0),
    ];
    expect(engine.find(days), isEmpty);
  });

  test('finds a strong negative sleep→spend link with an effect size', () {
    // Low sleep pairs with high spend; more sleep → less spend.
    final days = [
      _d(sleep: 4, spend: 200),
      _d(sleep: 4.5, spend: 190),
      _d(sleep: 5, spend: 180),
      _d(sleep: 7.5, spend: 110),
      _d(sleep: 8, spend: 100),
      _d(sleep: 8.5, spend: 90),
    ];
    final patterns = engine.find(days);
    final sleepSpend = patterns.firstWhere(
        (p) => p.driver == LifeMetric.sleep && p.outcome == LifeMetric.spend);
    expect(sleepSpend.corr, lessThan(-0.3)); // strong negative
    expect(sleepSpend.up, isFalse); // more sleep → less spend
    expect(sleepSpend.deltaPct.abs(), greaterThan(20)); // sizeable effect
    expect(sleepSpend.key, 'insight.cross.sleep_spend.down');
  });

  test('ignores links with no real effect', () {
    // Spend is flat regardless of sleep → no correlation.
    final days = [
      for (var i = 0; i < 8; i++)
        _d(sleep: 5 + (i % 4).toDouble(), spend: 150),
    ];
    expect(
        engine.find(days).where((p) => p.outcome == LifeMetric.spend), isEmpty);
  });
}

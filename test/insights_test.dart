import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/insights/domain/insight_engine.dart';

void main() {
  const engine = InsightEngine();

  group('pearson', () {
    test('perfect positive is 1', () {
      expect(engine.pearson([1, 2, 3], [2, 4, 6]), closeTo(1, 1e-9));
    });
    test('perfect negative is -1', () {
      expect(engine.pearson([1, 2, 3], [6, 4, 2]), closeTo(-1, 1e-9));
    });
    test('no variance is null', () {
      expect(engine.pearson([5, 5, 5], [1, 2, 3]), isNull);
      expect(engine.pearson([1], [1]), isNull);
    });
  });

  group('correlate', () {
    // Mood clearly rises with sleep; steps only in 3 points; spending constant.
    final points = <InsightPoint>[
      const InsightPoint(mood: 1, sleepHours: 5, steps: 3000, spendMajor: 10),
      const InsightPoint(mood: 2, sleepHours: 6, steps: 3000, spendMajor: 10),
      const InsightPoint(mood: 3, sleepHours: 7, steps: 3000, spendMajor: 10),
      const InsightPoint(mood: 4, sleepHours: 8, spendMajor: 10),
      const InsightPoint(mood: 5, sleepHours: 9, spendMajor: 10),
      const InsightPoint(mood: 5, sleepHours: 10, spendMajor: 10),
    ];

    test('reports the sleep→mood link and nothing spurious', () {
      final res = engine.correlate(points);
      // Sleep qualifies (6 samples, strong). Steps has only 3 samples (< min);
      // spending has no variance; water is absent → none of them appear.
      expect(res.length, 1);
      expect(res.single.driver, InsightDriver.sleep);
      expect(res.single.positive, isTrue);
      expect(res.single.samples, 6);
      expect(res.single.strength, greaterThan(0.6));
    });

    test('detects the stress→mood link (mood falls as stress rises)', () {
      final pts = [
        const InsightPoint(mood: 5, stress: 1),
        const InsightPoint(mood: 5, stress: 1),
        const InsightPoint(mood: 4, stress: 2),
        const InsightPoint(mood: 3, stress: 3),
        const InsightPoint(mood: 2, stress: 4),
        const InsightPoint(mood: 1, stress: 5),
      ];
      final res = engine.correlate(pts);
      expect(res.single.driver, InsightDriver.stress);
      expect(res.single.positive, isFalse); // higher stress → lower mood
      expect(res.single.strength, greaterThan(0.6));
    });

    test('drops a driver below the minimum sample size', () {
      final few = [
        const InsightPoint(mood: 1, sleepHours: 5),
        const InsightPoint(mood: 5, sleepHours: 9),
      ];
      expect(engine.correlate(few), isEmpty);
    });

    test('drops a driver whose effect is too small', () {
      // Symmetric mood over a monotonic water series → correlation is ~0, so it
      // stays below the effect-size threshold even with enough samples.
      final noise = [
        const InsightPoint(mood: 1, water: 1),
        const InsightPoint(mood: 2, water: 2),
        const InsightPoint(mood: 3, water: 3),
        const InsightPoint(mood: 3, water: 4),
        const InsightPoint(mood: 2, water: 5),
        const InsightPoint(mood: 1, water: 6),
      ];
      expect(engine.correlate(noise), isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/insights/domain/insight_engine.dart';

InsightPoint _p(double mood, double? training) =>
    InsightPoint(mood: mood, trainingMinutes: training);

void main() {
  const engine = InsightEngine();

  LifeInsight? training(List<InsightPoint> points) {
    final found = engine
        .correlate(points)
        .where((i) => i.driver == InsightDriver.training);
    return found.isEmpty ? null : found.first;
  }

  test('finds that mood is higher on training days', () {
    final insight = training([
      _p(2, 0),
      _p(2, 0),
      _p(3, 15),
      _p(4, 40),
      _p(4, 45),
      _p(5, 60),
      _p(3, 20),
      _p(2, 0),
    ])!;

    expect(insight.positive, isTrue);
    expect(insight.samples, 8);
  });

  test('finds the unhappy direction too, rather than only good news', () {
    // Someone training themselves into the ground deserves to be told.
    final insight = training([
      _p(5, 0),
      _p(5, 0),
      _p(4, 20),
      _p(3, 45),
      _p(2, 60),
      _p(2, 70),
      _p(4, 15),
      _p(5, 0),
    ])!;
    expect(insight.positive, isFalse);
  });

  group('it stays quiet when it should', () {
    test('a handful of days is not a pattern', () {
      expect(
        training([_p(3, 30), _p(4, 45), _p(2, 0)]),
        isNull,
        reason: 'below the minimum sample there is nothing honest to say',
      );
    });

    test('no relationship means no claim', () {
      final flat = [
        _p(3, 0),
        _p(4, 30),
        _p(3, 60),
        _p(4, 0),
        _p(3, 30),
        _p(4, 60),
        _p(3, 0),
        _p(4, 30),
      ];
      final found = training(flat);
      expect(found == null || found.strength < 0.5, isTrue);
    });

    test('a column of identical values yields nothing', () {
      // Every day trained exactly the same amount: no variance, no correlation,
      // and certainly no insight.
      expect(
        training([
          _p(2, 30),
          _p(3, 30),
          _p(4, 30),
          _p(5, 30),
          _p(1, 30),
          _p(3, 30),
        ]),
        isNull,
      );
    });
  });

  test('days without a session are zeroes, not gaps', () {
    // The comparison that makes the pattern mean anything is "the days I did
    // nothing", so those days have to be in the sample.
    final insight = training([
      _p(2, 0),
      _p(2, 0),
      _p(2, 0),
      _p(5, 45),
      _p(5, 50),
      _p(5, 40),
    ])!;
    expect(insight.samples, 6);
    expect(insight.positive, isTrue);
  });
}

import 'dart:math' as math;

/// A tracked daily life metric. Unlike [InsightEngine] (which correlates
/// everything against mood), the cross engine looks at relationships *between*
/// non-mood pillars — the connections a single-purpose app can never see.
enum LifeMetric { sleep, steps, water, spend }

/// One day's metrics (any subset may be present).
class DayMetrics {
  final Map<LifeMetric, double> values;
  const DayMetrics(this.values);
  double? get(LifeMetric m) => values[m];
}

/// A discovered relationship: as [driver] rises, [outcome] tends to move, with
/// [corr] strength and an approximate [deltaPct] effect (how much higher/lower
/// the outcome is on high-driver days vs low-driver days).
class CrossPattern {
  final LifeMetric driver;
  final LifeMetric outcome;
  final double corr; // Pearson, -1..1
  final int samples;
  final double deltaPct; // (highMean - lowMean) / lowMean * 100

  const CrossPattern({
    required this.driver,
    required this.outcome,
    required this.corr,
    required this.samples,
    required this.deltaPct,
  });

  bool get up => deltaPct >= 0; // more driver → more outcome
  double get strength => corr.abs();

  /// i18n key stem: `insight.cross.<driver>_<outcome>.<up|down>`.
  String get key =>
      'insight.cross.${driver.name}_${outcome.name}.${up ? 'up' : 'down'}';

  /// i18n key for the actionable "try this" suggestion for this pattern.
  String get tipKey => '$key.tip';
}

/// Finds honest relationships between non-mood pillars over a curated set of
/// pairs (so it never data-dredges). Requires a minimum sample and effect size.
/// Pure — unit-tested.
class CrossInsightEngine {
  const CrossInsightEngine();

  static const int minSamples = 6;
  static const double minAbsCorr = 0.3;

  /// The only pairs we check — each is a plausible, explainable link.
  static const pairs = <(LifeMetric, LifeMetric)>[
    (LifeMetric.sleep, LifeMetric.spend),
    (LifeMetric.sleep, LifeMetric.steps),
    (LifeMetric.steps, LifeMetric.spend),
    (LifeMetric.water, LifeMetric.steps),
  ];

  List<CrossPattern> find(List<DayMetrics> days) {
    final out = <CrossPattern>[];
    for (final (driver, outcome) in pairs) {
      final xs = <double>[];
      final ys = <double>[];
      for (final d in days) {
        final x = d.get(driver);
        final y = d.get(outcome);
        if (x != null && y != null) {
          xs.add(x);
          ys.add(y);
        }
      }
      if (xs.length < minSamples) continue;
      final r = _pearson(xs, ys);
      if (r == null || r.abs() < minAbsCorr) continue;
      out.add(CrossPattern(
        driver: driver,
        outcome: outcome,
        corr: r,
        samples: xs.length,
        deltaPct: _deltaPct(xs, ys),
      ));
    }
    out.sort((a, b) => b.strength.compareTo(a.strength));
    return out;
  }

  /// Percentage difference in [ys] between the high-[xs] half and the low-half.
  double _deltaPct(List<double> xs, List<double> ys) {
    final idx = List.generate(xs.length, (i) => i)
      ..sort((a, b) => xs[a].compareTo(xs[b]));
    final half = idx.length ~/ 2;
    if (half == 0) return 0;
    final low = idx.take(half);
    final high = idx.skip(idx.length - half);
    double mean(Iterable<int> g) =>
        g.map((i) => ys[i]).fold(0.0, (a, b) => a + b) / g.length;
    final lowMean = mean(low);
    final highMean = mean(high);
    if (lowMean == 0) return 0;
    return (highMean - lowMean) / lowMean * 100;
  }

  double? _pearson(List<double> xs, List<double> ys) {
    final n = xs.length;
    if (n < 2) return null;
    final mx = xs.reduce((a, b) => a + b) / n;
    final my = ys.reduce((a, b) => a + b) / n;
    var sxy = 0.0, sxx = 0.0, syy = 0.0;
    for (var i = 0; i < n; i++) {
      final dx = xs[i] - mx;
      final dy = ys[i] - my;
      sxy += dx * dy;
      sxx += dx * dx;
      syy += dy * dy;
    }
    if (sxx == 0 || syy == 0) return null;
    return sxy / (math.sqrt(sxx) * math.sqrt(syy));
  }
}

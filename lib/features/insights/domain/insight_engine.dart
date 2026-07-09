import 'dart:math' as math;

/// What a mood correlation is measured against.
enum InsightDriver { sleep, steps, water, spending, stress }

/// A discovered relationship between daily mood and one life driver.
class LifeInsight {
  final InsightDriver driver;

  /// Pearson correlation coefficient, −1..1. Positive = mood rises with the
  /// driver; negative = mood falls as the driver rises.
  final double corr;
  final int samples;

  const LifeInsight({
    required this.driver,
    required this.corr,
    required this.samples,
  });

  bool get positive => corr >= 0;
  double get strength => corr.abs();
}

/// One day's mood paired with the drivers logged that day (any driver may be
/// missing).
class InsightPoint {
  final double mood; // 1..5
  final double? sleepHours;
  final double? steps;
  final double? water;
  final double? spendMajor;
  final double? stress; // perceived stress 1..5

  const InsightPoint({
    required this.mood,
    this.sleepHours,
    this.steps,
    this.water,
    this.spendMajor,
    this.stress,
  });
}

/// Finds honest, non-medical correlations between daily mood and sleep, steps,
/// water and spending. Requires a minimum sample and a minimum effect size so it
/// never reports noise. Pure — unit-tested.
class InsightEngine {
  const InsightEngine();

  static const int minSamples = 6;
  static const double minAbsCorr = 0.25;

  List<LifeInsight> correlate(List<InsightPoint> points) {
    final out = <LifeInsight>[];

    void tryDriver(InsightDriver d, double? Function(InsightPoint) select) {
      final xs = <double>[];
      final ys = <double>[];
      for (final p in points) {
        final v = select(p);
        if (v != null) {
          xs.add(v);
          ys.add(p.mood);
        }
      }
      if (xs.length < minSamples) return;
      final r = pearson(xs, ys);
      if (r == null || r.abs() < minAbsCorr) return;
      out.add(LifeInsight(driver: d, corr: r, samples: xs.length));
    }

    tryDriver(InsightDriver.sleep, (p) => p.sleepHours);
    tryDriver(InsightDriver.steps, (p) => p.steps);
    tryDriver(InsightDriver.water, (p) => p.water);
    tryDriver(InsightDriver.spending, (p) => p.spendMajor);
    tryDriver(InsightDriver.stress, (p) => p.stress);

    out.sort((a, b) => b.strength.compareTo(a.strength));
    return out;
  }

  /// Pearson correlation, or null when it's undefined (n < 2 or a series has no
  /// variance).
  double? pearson(List<double> xs, List<double> ys) {
    final n = xs.length;
    if (n < 2 || ys.length != n) return null;
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

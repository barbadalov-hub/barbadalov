// STAGED — native build only. Not compiled by the web build (see
// analysis_options.yaml `exclude: native/**`). Activate per native/README.md.
//
// Live on-device step counting via the `pedometer` package (iOS CMPedometer /
// Android step-counter sensor). This complements the HealthKit/Google Fit
// pull in device_health_source_real.dart: HealthKit gives the authoritative
// daily total (incl. Apple Watch), while this gives a *live* count that ticks
// up while the app is open — nice for the Today rings.
//
// The OS step-counter sensor reports a cumulative count since device boot, so
// "today's steps" = current cumulative − the cumulative captured at local
// midnight. We persist that midnight baseline so it survives app restarts.

import 'dart:async';

import 'package:pedometer/pedometer.dart';

/// Today's step count derived from the cumulative sensor value.
class TodaySteps {
  final int steps;
  final DateTime at;
  const TodaySteps(this.steps, this.at);
}

/// Wraps [Pedometer.stepCountStream] and turns the boot-cumulative counter into
/// a per-day count. Feed [stream] into `LogHealth.setSteps` (debounced) to keep
/// the health day live; on iOS this requires the Motion & Fitness permission
/// (NSMotionUsageDescription).
class PedometerSource {
  /// Reads/writes the midnight baseline `(dayKey -> cumulativeAtMidnight)`.
  final int? Function(String dayKey) readBaseline;
  final void Function(String dayKey, int cumulative) writeBaseline;

  PedometerSource({required this.readBaseline, required this.writeBaseline});

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Stream<TodaySteps> get stream => Pedometer.stepCountStream.map((event) {
        final now = event.timeStamp;
        final key = _dayKey(now);
        var baseline = readBaseline(key);
        // First reading of the day: this cumulative value is our zero point.
        if (baseline == null || event.steps < baseline) {
          baseline = event.steps;
          writeBaseline(key, baseline);
        }
        final today = (event.steps - baseline).clamp(0, 1 << 31);
        return TodaySteps(today, now);
      });
}

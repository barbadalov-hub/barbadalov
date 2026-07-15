// STAGED — native build only. Not compiled by the web build (see
// analysis_options.yaml `exclude: native/**`). Activate per native/README.md.
//
// A real [DeviceHealthSource] that reads steps, sleep and heart rate from
// Apple HealthKit / Google Fit / Health Connect via the `health` package.
// Apple Watch and other wearables feed HealthKit, so their data arrives here
// automatically — no per-device code.
//
// When wired in, this replaces `MockDeviceHealthSource` behind the existing
// `deviceHealthSourceProvider` seam; `SyncDeviceHealth` and the whole sync UI
// stay exactly the same.

import 'package:health/health.dart';
import 'package:lifeos/core/devices/device_health_source.dart';

class RealDeviceHealthSource implements DeviceHealthSource {
  final Health _health;
  final String deviceName;
  bool _authorized = false;

  RealDeviceHealthSource({Health? health, this.deviceName = 'Apple Health'})
      : _health = health ?? Health();

  static const _types = <HealthDataType>[
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.HEART_RATE,
  ];

  /// Ask the OS for read permission. Call once before [read]; safe to re-call.
  Future<bool> requestPermission() async {
    final ok = await _health.requestAuthorization(
      _types,
      permissions: List.filled(_types.length, HealthDataAccess.READ),
    );
    _authorized = ok;
    return ok;
  }

  @override
  bool get isAvailable => _authorized;

  @override
  String get name => deviceName;

  @override
  Future<DeviceHealthSnapshot> read() async {
    if (!_authorized) await requestPermission();

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    // Steps: HealthKit gives a convenient interval total.
    final steps = await _health.getTotalStepsInInterval(midnight, now) ?? 0;

    // Sleep last night: sum SLEEP_ASLEEP minutes over the past 24h.
    final since = now.subtract(const Duration(hours: 24));
    final points = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.SLEEP_ASLEEP, HealthDataType.HEART_RATE],
      startTime: since,
      endTime: now,
    );

    var sleepMinutes = 0.0;
    int? latestHr;
    DateTime? latestHrAt;
    for (final p in points) {
      switch (p.type) {
        case HealthDataType.SLEEP_ASLEEP:
          sleepMinutes +=
              p.dateTo.difference(p.dateFrom).inMinutes.toDouble();
        case HealthDataType.HEART_RATE:
          final v = p.value;
          if (v is NumericHealthValue &&
              (latestHrAt == null || p.dateFrom.isAfter(latestHrAt))) {
            latestHr = v.numericValue.round();
            latestHrAt = p.dateFrom;
          }
        default:
          break;
      }
    }

    return DeviceHealthSnapshot(
      steps: steps,
      sleepHours: sleepMinutes / 60.0,
      heartRate: latestHr,
    );
  }
}

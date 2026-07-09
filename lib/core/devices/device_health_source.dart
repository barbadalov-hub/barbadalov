import 'dart:math';

/// A reading pulled from a wearable / health platform.
class DeviceHealthSnapshot {
  final int steps;
  final double sleepHours;
  final int? heartRate;

  const DeviceHealthSnapshot({
    required this.steps,
    required this.sleepHours,
    this.heartRate,
  });
}

/// Port for device/health-platform integrations. Phase 11 ships a mock; the real
/// adapter (HealthKit / Google Fit / Fitbit / Garmin) implements this same
/// interface using the `health` package. See docs/DEVICES.md.
abstract class DeviceHealthSource {
  /// Whether a device/platform is connected and permission granted.
  bool get isAvailable;

  /// Human label for the connected source, e.g. "Apple Health".
  String get name;

  Future<DeviceHealthSnapshot> read();
}

/// Simulates a connected wearable so the sync flow works on desktop/web today.
/// On a phone build, swap in the `health`-package adapter (docs/DEVICES.md) —
/// the selected device name and the whole sync UI stay the same.
class MockDeviceHealthSource implements DeviceHealthSource {
  final Random _random;
  final String deviceName;
  MockDeviceHealthSource({Random? random, this.deviceName = 'Smart watch'})
      : _random = random ?? Random();

  @override
  bool get isAvailable => true;

  @override
  String get name => deviceName;

  @override
  Future<DeviceHealthSnapshot> read() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return DeviceHealthSnapshot(
      steps: 6000 + _random.nextInt(6000),
      sleepHours: 6 + _random.nextDouble() * 2.5,
      heartRate: 58 + _random.nextInt(20),
    );
  }
}

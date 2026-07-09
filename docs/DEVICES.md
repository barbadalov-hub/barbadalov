# Phase 11 — Device integration

LifeOS reads wearable/health-platform data through one port,
`DeviceHealthSource` (`lib/core/devices/device_health_source.dart`). Phase 11
ships `MockDeviceHealthSource` so the sync flow is demoable offline. Device data
is folded into HealthOS through the *same* use cases and events as manual
logging (`steps_updated`, `sleep_logged`) — there is no privileged path.

## Real adapter (Apple HealthKit / Google Fit / Fitbit / Garmin)

Use the [`health`](https://pub.dev/packages/health) package.

```yaml
# pubspec.yaml
dependencies:
  health: ^11.0.0
```

```dart
import 'package:health/health.dart';
import 'package:lifeos/core/devices/device_health_source.dart';

class PlatformHealthSource implements DeviceHealthSource {
  final Health _health = Health();
  bool _granted = false;

  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.HEART_RATE,
  ];

  Future<void> connect() async {
    _granted = await _health.requestAuthorization(_types);
  }

  @override
  bool get isAvailable => _granted;

  @override
  String get name => 'Apple Health / Google Fit';

  @override
  Future<DeviceHealthSnapshot> read() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final steps = await _health.getTotalStepsInInterval(start, now) ?? 0;
    // ...aggregate SLEEP_ASLEEP + latest HEART_RATE similarly...
    return DeviceHealthSnapshot(steps: steps, sleepHours: 0, heartRate: null);
  }
}
```

Then point `deviceHealthSourceProvider` at `PlatformHealthSource` and call
`connect()` on first use.

## Platform setup

- **iOS**: add HealthKit capability in Xcode; `NSHealthShareUsageDescription`
  and `NSHealthUpdateUsageDescription` in `Info.plist`.
- **Android**: Health Connect permissions in `AndroidManifest.xml`; on Android
  14+ declare the specific record types.

## Headphones module (optional, spec §14)

Model as another `DeviceHealthSource`-style port emitting a `listening_logged`
event with duration; a handler raises a 🟢 OPTIONAL "time to rest your ears"
notification after sustained exposure. Same event → engine → handler shape as
everything else.

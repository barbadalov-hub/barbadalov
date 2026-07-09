import 'package:lifeos/core/devices/device_health_source.dart';
import 'package:lifeos/features/health/application/health_use_cases.dart';

/// Pulls a reading from a [DeviceHealthSource] and folds it into HealthOS via
/// the normal use cases — so device data flows through the *same* events as
/// manual logging (steps_updated, sleep_logged). No special path.
class SyncDeviceHealth {
  final DeviceHealthSource _source;
  final LogHealth _logHealth;

  const SyncDeviceHealth(this._source, this._logHealth);

  bool get isAvailable => _source.isAvailable;
  String get sourceName => _source.name;

  Future<DeviceHealthSnapshot> call({String userId = 'local'}) async {
    final snapshot = await _source.read();
    _logHealth.setSteps(snapshot.steps, userId: userId);
    _logHealth.logSleep(snapshot.sleepHours, userId: userId);
    final hr = snapshot.heartRate;
    if (hr != null) _logHealth.setHeartRate(hr, userId: userId);
    return snapshot;
  }
}

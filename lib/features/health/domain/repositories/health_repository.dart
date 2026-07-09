import 'package:lifeos/features/health/domain/entities/health_day.dart';

/// Stores health metrics for the current day (Phase 8). Multi-day history is a
/// later enhancement; the interface already returns a [HealthDay] keyed by date.
abstract class HealthRepository {
  HealthDay today();
  void update(HealthDay day);
  Stream<HealthDay> watchToday();
}

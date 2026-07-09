import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/health/domain/entities/measurement.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// Persisted body-measurement history. One reading per field per day (upsert).
class MeasurementController extends Notifier<List<MeasurementEntry>> {
  static const _key = 'health.measurements';
  static const _cap = 500;

  @override
  List<MeasurementEntry> build() {
    return [
      ...ref.watch(jsonStoreProvider).loadList<MeasurementEntry>(
            _key,
            MeasurementEntry.fromJson,
            fallback: const [],
          ),
    ]..sort((a, b) => a.date.compareTo(b.date));
  }

  void log(MeasurementField field, double cm, {DateTime? date}) {
    if (cm <= 0) return;
    final day = _dateOnly(date ?? ref.read(clockProvider).now());
    final next = [
      for (final e in state)
        if (!(e.field == field && _sameDay(e.date, day))) e,
      MeasurementEntry(date: day, field: field, cm: cm),
    ]..sort((a, b) => a.date.compareTo(b.date));
    final trimmed = next.length > _cap ? next.sublist(next.length - _cap) : next;
    ref.read(jsonStoreProvider).saveList<MeasurementEntry>(
          _key,
          trimmed,
          (e) => e.toJson(),
        );
    state = trimmed;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

final measurementsProvider =
    NotifierProvider<MeasurementController, List<MeasurementEntry>>(
        MeasurementController.new);

/// Chronological readings for one field.
List<MeasurementEntry> measurementSeries(
        List<MeasurementEntry> all, MeasurementField field) =>
    [for (final e in all) if (e.field == field) e];

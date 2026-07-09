import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// A manual vitals reading: blood pressure (systolic/diastolic) + resting pulse.
class VitalsEntry extends Equatable {
  final DateTime date;
  final int systolic;
  final int diastolic;
  final int pulse;

  const VitalsEntry({
    required this.date,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
  });

  /// AHA-style rough band for the systolic/diastolic pair (i18n key).
  String get bandKey {
    if (systolic >= 140 || diastolic >= 90) return 'vitals.high2';
    if (systolic >= 130 || diastolic >= 80) return 'vitals.high1';
    if (systolic >= 120) return 'vitals.elevated';
    return 'vitals.normal';
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'systolic': systolic,
        'diastolic': diastolic,
        'pulse': pulse,
      };

  factory VitalsEntry.fromJson(Map<String, dynamic> j) => VitalsEntry(
        date: DateTime.parse(j['date'] as String),
        systolic: (j['systolic'] as num?)?.toInt() ?? 0,
        diastolic: (j['diastolic'] as num?)?.toInt() ?? 0,
        pulse: (j['pulse'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [date, systolic, diastolic, pulse];
}

class VitalsController extends Notifier<List<VitalsEntry>> {
  static const _key = 'health.vitals';
  static const _cap = 400;

  @override
  List<VitalsEntry> build() {
    return [
      ...ref.watch(jsonStoreProvider).loadList<VitalsEntry>(
            _key,
            VitalsEntry.fromJson,
            fallback: const [],
          ),
    ]..sort((a, b) => a.date.compareTo(b.date));
  }

  void log(VitalsEntry entry) {
    final next = [...state, entry]..sort((a, b) => a.date.compareTo(b.date));
    final trimmed = next.length > _cap ? next.sublist(next.length - _cap) : next;
    ref.read(jsonStoreProvider).saveList<VitalsEntry>(
          _key,
          trimmed,
          (e) => e.toJson(),
        );
    state = trimmed;
  }
}

final vitalsProvider =
    NotifierProvider<VitalsController, List<VitalsEntry>>(VitalsController.new);

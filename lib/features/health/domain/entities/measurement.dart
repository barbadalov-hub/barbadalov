import 'package:equatable/equatable.dart';

/// Body measurements tracked over time (weight has its own history already).
enum MeasurementField {
  waist('📐', 'meas.waist'),
  chest('👕', 'meas.chest'),
  hips('📏', 'meas.hips'),
  arm('💪', 'meas.arm'),
  neck('🧣', 'meas.neck');

  const MeasurementField(this.emoji, this.labelKey);
  final String emoji;
  final String labelKey;

  static MeasurementField fromName(String n) =>
      values.firstWhere((f) => f.name == n, orElse: () => MeasurementField.waist);
}

/// One measurement reading (cm) on a given day.
class MeasurementEntry extends Equatable {
  final DateTime date;
  final MeasurementField field;
  final double cm;

  const MeasurementEntry({
    required this.date,
    required this.field,
    required this.cm,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'field': field.name,
        'cm': cm,
      };

  factory MeasurementEntry.fromJson(Map<String, dynamic> j) => MeasurementEntry(
        date: DateTime.parse(j['date'] as String),
        field: MeasurementField.fromName(j['field'] as String? ?? 'waist'),
        cm: (j['cm'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [date, field, cm];
}

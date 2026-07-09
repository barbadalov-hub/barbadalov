import 'package:equatable/equatable.dart';

/// Bleeding intensity for a day (0 = none … 3 = heavy).
enum FlowLevel {
  none('', 'flow.none'),
  light('🩸', 'flow.light'),
  medium('🩸🩸', 'flow.medium'),
  heavy('🩸🩸🩸', 'flow.heavy');

  const FlowLevel(this.emoji, this.labelKey);
  final String emoji;
  final String labelKey;

  static FlowLevel fromIndex(int i) =>
      values[(i).clamp(0, values.length - 1)];
}

/// A taggable symptom.
class Symptom {
  final String id;
  final String emoji;
  final String labelKey;
  const Symptom(this.id, this.emoji, this.labelKey);
}

class Symptoms {
  const Symptoms._();
  static const all = <Symptom>[
    Symptom('cramps', '🌀', 'sym.cramps'),
    Symptom('headache', '🤕', 'sym.headache'),
    Symptom('bloating', '🎈', 'sym.bloating'),
    Symptom('tender', '💗', 'sym.tender'),
    Symptom('acne', '🧴', 'sym.acne'),
    Symptom('fatigue', '🥱', 'sym.fatigue'),
    Symptom('cravings', '🍫', 'sym.cravings'),
    Symptom('backache', '🔙', 'sym.backache'),
    Symptom('nausea', '🤢', 'sym.nausea'),
    Symptom('moodSwings', '🎭', 'sym.moodSwings'),
  ];

  static Symptom? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}

/// One day's cycle diary entry (flow + symptoms + note). Upsert by date.
class CycleDayLog extends Equatable {
  final DateTime date;
  final int flow; // FlowLevel index
  final List<String> symptoms;
  final String note;

  const CycleDayLog({
    required this.date,
    this.flow = 0,
    this.symptoms = const [],
    this.note = '',
  });

  FlowLevel get flowLevel => FlowLevel.fromIndex(flow);
  bool get isEmpty => flow == 0 && symptoms.isEmpty && note.isEmpty;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'flow': flow,
        'symptoms': symptoms,
        'note': note,
      };

  factory CycleDayLog.fromJson(Map<String, dynamic> j) => CycleDayLog(
        date: DateTime.parse(j['date'] as String),
        flow: (j['flow'] as num?)?.toInt() ?? 0,
        symptoms: [for (final s in (j['symptoms'] as List? ?? [])) '$s'],
        note: (j['note'] as String?) ?? '',
      );

  @override
  List<Object?> get props => [date, flow, symptoms, note];
}

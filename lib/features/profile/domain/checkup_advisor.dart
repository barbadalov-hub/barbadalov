import 'package:lifeos/features/profile/domain/entities/user_profile.dart';
import 'package:lifeos/features/profile/domain/fitness_calculator.dart';

enum CheckupKind { doctor, lab }

/// A suggested doctor visit or lab test, with the reason it's suggested.
/// Educational prompts to discuss with a real doctor — never a diagnosis.
class CheckupSuggestion {
  final CheckupKind kind;
  final String id;
  final String reasonKey;
  const CheckupSuggestion(this.kind, this.id, this.reasonKey);

  String get labelKey => 'checkup.${kind.name}.$id';
}

/// Suggests age/sex/body-appropriate check-ups and lab tests from the profile.
/// Rule-based, conservative, and framed as "worth asking your doctor about".
/// Pure — unit-tested.
List<CheckupSuggestion> suggestCheckups(
    UserProfile p, FitnessAssessment a) {
  final out = <CheckupSuggestion>[];
  void add(CheckupKind k, String id, String reason) {
    if (!out.any((s) => s.kind == k && s.id == id)) {
      out.add(CheckupSuggestion(k, id, reason));
    }
  }

  // Everyone: a yearly baseline.
  add(CheckupKind.doctor, 'gp', 'checkup.reason.annual');
  add(CheckupKind.lab, 'cbc', 'checkup.reason.annual');

  // Raised weight → metabolic work-up.
  if (a.bmi >= 25) {
    add(CheckupKind.lab, 'glucose', 'checkup.reason.weight');
    add(CheckupKind.lab, 'lipids', 'checkup.reason.weight');
    add(CheckupKind.doctor, 'endocrinologist', 'checkup.reason.weight');
  }
  // Obesity or high waist-hip ratio → heart risk.
  if (a.bmi >= 30 || a.whrHighRisk) {
    add(CheckupKind.doctor, 'cardiologist', 'checkup.reason.cardio');
    add(CheckupKind.lab, 'lipids', 'checkup.reason.cardio');
  }
  // Age 40+.
  if (p.age >= 40) {
    add(CheckupKind.doctor, 'cardiologist', 'checkup.reason.age40');
    add(CheckupKind.lab, 'thyroid', 'checkup.reason.age40');
  }
  // Sex-specific.
  if (p.sex == Sex.female) {
    add(CheckupKind.doctor, 'gynecologist', 'checkup.reason.women');
  }
  if (p.sex == Sex.male && p.age >= 45) {
    add(CheckupKind.doctor, 'urologist', 'checkup.reason.men45');
  }
  // Desk job / little sun → vitamin D.
  if (p.deskJob) {
    add(CheckupKind.lab, 'vitd', 'checkup.reason.desk');
  }

  // Doctors first, then labs.
  out.sort((x, y) => x.kind.index.compareTo(y.kind.index));
  return out;
}

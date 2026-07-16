/// Therapeutic ("table") diets that are only appropriate **on a doctor's
/// prescription** — gastritis/ulcer, liver, kidney, obesity, diabetes, heart.
/// The app never prescribes these; it only shows them, and marks one as active
/// after the user confirms their own doctor recommended it.
class MedicalDiet {
  final String id;
  final String emoji;
  const MedicalDiet(this.id, this.emoji);

  String get nameKey => 'meddiet.$id.name';
  String get conditionKey => 'meddiet.$id.condition';
  String get eatKey => 'meddiet.$id.eat';
  String get avoidKey => 'meddiet.$id.avoid';
  String get cookKey => 'meddiet.$id.cook';
}

const kMedicalDiets = <MedicalDiet>[
  MedicalDiet('table1', '🍵'), // gastritis / ulcer
  MedicalDiet('table5', '🥗'), // liver / gallbladder
  MedicalDiet('table7', '💧'), // kidney
  MedicalDiet('table8', '⚖️'), // obesity
  MedicalDiet('table9', '🩺'), // diabetes
  MedicalDiet('table10', '❤️'), // heart / hypertension
];

MedicalDiet? medicalDietById(String id) {
  for (final d in kMedicalDiets) {
    if (d.id == id) return d;
  }
  return null;
}

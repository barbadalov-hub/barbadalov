import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/profile/domain/checkup_advisor.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';
import 'package:lifeos/features/profile/domain/fitness_calculator.dart';

UserProfile _p({
  Sex sex = Sex.male,
  int age = 30,
  double height = 180,
  double weight = 75,
  bool desk = true,
}) =>
    UserProfile(
      name: 'A',
      sex: sex,
      age: age,
      heightCm: height,
      weightKg: weight,
      deskJob: desk,
    );

void main() {
  const calc = FitnessCalculator();
  List<CheckupSuggestion> run(UserProfile p) => suggestCheckups(p, calc.assess(p));

  bool has(List<CheckupSuggestion> s, CheckupKind k, String id) =>
      s.any((x) => x.kind == k && x.id == id);

  test('everyone gets a GP and a blood count', () {
    final s = run(_p());
    expect(has(s, CheckupKind.doctor, 'gp'), isTrue);
    expect(has(s, CheckupKind.lab, 'cbc'), isTrue);
  });

  test('high BMI adds a metabolic work-up', () {
    final s = run(_p(height: 170, weight: 100)); // BMI ~34.6
    expect(has(s, CheckupKind.doctor, 'endocrinologist'), isTrue);
    expect(has(s, CheckupKind.lab, 'glucose'), isTrue);
    expect(has(s, CheckupKind.lab, 'lipids'), isTrue);
    expect(has(s, CheckupKind.doctor, 'cardiologist'), isTrue); // obese
  });

  test('sex- and age-specific suggestions', () {
    expect(has(run(_p(sex: Sex.female)), CheckupKind.doctor, 'gynecologist'),
        isTrue);
    expect(has(run(_p(sex: Sex.male, age: 50)), CheckupKind.doctor, 'urologist'),
        isTrue);
    expect(has(run(_p(age: 45)), CheckupKind.doctor, 'cardiologist'), isTrue);
  });

  test('no duplicates and doctors come before labs', () {
    final s = run(_p(height: 170, weight: 100, age: 50));
    final ids = s.map((x) => '${x.kind}/${x.id}').toList();
    expect(ids.toSet().length, ids.length); // unique
    final lastDoctor = s.lastIndexWhere((x) => x.kind == CheckupKind.doctor);
    final firstLab = s.indexWhere((x) => x.kind == CheckupKind.lab);
    expect(lastDoctor, lessThan(firstLab));
  });
}

import 'package:equatable/equatable.dart';

enum Sex { male, female }

enum FitnessGoal { lose, maintain, gain }

/// The user's body & lifestyle profile — the input to the built-in dietitian.
/// Height/weight/age/sex are required for energy math; circumferences are
/// optional and unlock extra metrics (waist-hip ratio, body-fat estimate).
class UserProfile extends Equatable {
  final String name;
  final Sex sex;
  final int age;
  final double heightCm;
  final double weightKg;

  // Optional tape measurements (cm).
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? armCm;
  final double? neckCm;

  /// Lifestyle: does the user sit at a desk most of the day (e.g. 10:00–19:00
  /// at a computer), and how many workout sessions per week (e.g. treadmill
  /// Tue/Thu 7:30–9:00 = 2).
  final bool deskJob;
  final int workoutsPerWeek;

  final FitnessGoal goal;

  const UserProfile({
    required this.name,
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.armCm,
    this.neckCm,
    this.deskJob = true,
    this.workoutsPerWeek = 0,
    this.goal = FitnessGoal.maintain,
  });

  /// Copy with a new weight — used when the user logs weight in HealthOS so
  /// the dietitian recalibrates automatically.
  UserProfile withWeight(double weightKg) => UserProfile(
        name: name,
        sex: sex,
        age: age,
        heightCm: heightCm,
        weightKg: weightKg,
        chestCm: chestCm,
        waistCm: waistCm,
        hipsCm: hipsCm,
        armCm: armCm,
        neckCm: neckCm,
        deskJob: deskJob,
        workoutsPerWeek: workoutsPerWeek,
        goal: goal,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'sex': sex.name,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'chestCm': chestCm,
        'waistCm': waistCm,
        'hipsCm': hipsCm,
        'armCm': armCm,
        'neckCm': neckCm,
        'deskJob': deskJob,
        'workoutsPerWeek': workoutsPerWeek,
        'goal': goal.name,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: (json['name'] as String?) ?? '',
        sex: Sex.values.byName((json['sex'] as String?) ?? 'male'),
        age: (json['age'] as int?) ?? 30,
        heightCm: (json['heightCm'] as num).toDouble(),
        weightKg: (json['weightKg'] as num).toDouble(),
        chestCm: (json['chestCm'] as num?)?.toDouble(),
        waistCm: (json['waistCm'] as num?)?.toDouble(),
        hipsCm: (json['hipsCm'] as num?)?.toDouble(),
        armCm: (json['armCm'] as num?)?.toDouble(),
        neckCm: (json['neckCm'] as num?)?.toDouble(),
        deskJob: (json['deskJob'] as bool?) ?? true,
        workoutsPerWeek: (json['workoutsPerWeek'] as int?) ?? 0,
        goal: FitnessGoal.values.byName((json['goal'] as String?) ?? 'maintain'),
      );

  @override
  List<Object?> get props => [
        name, sex, age, heightCm, weightKg, chestCm, waistCm, hipsCm, armCm,
        neckCm, deskJob, workoutsPerWeek, goal, //
      ];
}

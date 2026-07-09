import 'package:lifeos/core/events/life_event.dart';

/// Emitted whenever the user saves their body/lifestyle profile.
class ProfileUpdatedEvent extends LifeEvent {
  final double weightKg;
  final double heightCm;
  final String goal;

  const ProfileUpdatedEvent({
    required super.id,
    required super.userId,
    required super.occurredAt,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
  });

  @override
  String get type => 'profile_updated';

  @override
  Map<String, dynamic> toPayload() =>
      {'weightKg': weightKg, 'heightCm': heightCm, 'goal': goal};
}

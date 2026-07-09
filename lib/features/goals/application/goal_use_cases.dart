import 'package:lifeos/core/errors/failures.dart';
import 'package:lifeos/core/events/event_bus.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/id_service.dart';
import 'package:lifeos/core/utils/result.dart';
import 'package:lifeos/features/goals/domain/entities/goal.dart';
import 'package:lifeos/features/goals/domain/events/goal_events.dart';
import 'package:lifeos/features/goals/domain/repositories/goal_repository.dart';
import 'package:lifeos/shared/models/money.dart';

class AddGoal {
  final GoalRepository _repository;
  final EventBus _eventBus;
  final IdService _idService;
  final Clock _clock;

  const AddGoal(this._repository, this._eventBus, this._idService, this._clock);

  Result<Goal> call({
    required String title,
    required Money target,
    String emoji = '🎯',
    Money? saved,
    DateTime? targetDate,
    String userId = 'local',
  }) {
    if (title.trim().isEmpty) {
      return const Err(ValidationFailure('Title cannot be empty.'));
    }
    if (!target.isPositive) {
      return const Err(ValidationFailure('Target must be greater than zero.'));
    }
    final goal = Goal(
      id: _idService.newId(),
      title: title.trim(),
      emoji: emoji,
      target: target,
      saved: saved ?? Money.zero(currency: target.currency),
      targetDate: targetDate,
    );
    _repository.add(goal);
    _eventBus.publish(GoalCreatedEvent(
      id: _idService.newId(),
      userId: userId,
      occurredAt: _clock.now(),
      goalId: goal.id,
      title: goal.title,
      targetMinorUnits: goal.target.minorUnits,
    ));
    return Ok(goal);
  }
}

class AddMilestone {
  final GoalRepository _repository;
  const AddMilestone(this._repository);

  void call(Goal goal, String title) {
    if (title.trim().isEmpty) return;
    _repository.update(goal.addMilestone(title));
  }
}

class ToggleMilestone {
  final GoalRepository _repository;
  const ToggleMilestone(this._repository);

  void call(Goal goal, int index) =>
      _repository.update(goal.toggleMilestone(index));
}

class ContributeToGoal {
  final GoalRepository _repository;
  final EventBus _eventBus;
  final IdService _idService;
  final Clock _clock;

  const ContributeToGoal(
      this._repository, this._eventBus, this._idService, this._clock);

  Result<Goal> call(Goal goal, Money amount, {String userId = 'local'}) {
    if (!amount.isPositive) {
      return const Err(ValidationFailure('Amount must be greater than zero.'));
    }
    final updated = goal.contribute(amount);
    _repository.update(updated);
    _eventBus.publish(GoalUpdatedEvent(
      id: _idService.newId(),
      userId: userId,
      occurredAt: _clock.now(),
      goalId: updated.id,
      savedMinorUnits: updated.saved.minorUnits,
    ));
    return Ok(updated);
  }
}

import 'package:lifeos/core/errors/failures.dart';
import 'package:lifeos/core/events/event_bus.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/id_service.dart';
import 'package:lifeos/core/utils/result.dart';
import 'package:lifeos/features/mind/domain/entities/book.dart';
import 'package:lifeos/features/mind/domain/entities/day_task.dart';
import 'package:lifeos/features/mind/domain/entities/habit.dart';
import 'package:lifeos/features/mind/domain/events/mind_events.dart';
import 'package:lifeos/features/mind/domain/repositories/mind_repository.dart';

class ToggleHabit {
  final MindRepository _repository;
  final EventBus _eventBus;
  final IdService _idService;
  final Clock _clock;

  const ToggleHabit(
      this._repository, this._eventBus, this._idService, this._clock);

  void call(Habit habit, {String userId = 'local'}) {
    _repository.toggleHabit(habit.id, _clock.now());
    _eventBus.publish(HabitCompletedEvent(
      id: _idService.newId(),
      userId: userId,
      occurredAt: _clock.now(),
      habitId: habit.id,
      completed: !habit.doneToday,
    ));
  }
}

/// Create a new habit with a weekly target (7 = daily).
class AddHabit {
  final MindRepository _repository;
  final IdService _idService;

  const AddHabit(this._repository, this._idService);

  Result<Habit> call({
    required String name,
    String emoji = '✅',
    int targetPerWeek = 7,
  }) {
    if (name.trim().isEmpty) {
      return const Err(ValidationFailure('Habit cannot be empty.'));
    }
    final habit = Habit(
      id: _idService.newId(),
      name: name.trim(),
      emoji: emoji,
      targetPerWeek: targetPerWeek.clamp(1, 7),
    );
    _repository.addHabit(habit);
    return Ok(habit);
  }
}

class ToggleTask {
  final MindRepository _repository;
  final EventBus _eventBus;
  final IdService _idService;
  final Clock _clock;

  const ToggleTask(
      this._repository, this._eventBus, this._idService, this._clock);

  void call(DayTask task, {String userId = 'local'}) {
    _repository.toggleTask(task.id);
    _eventBus.publish(TaskCompletedEvent(
      id: _idService.newId(),
      userId: userId,
      occurredAt: _clock.now(),
      taskId: task.id,
      completed: !task.done,
    ));
  }
}

class AddTask {
  final MindRepository _repository;
  final IdService _idService;

  const AddTask(this._repository, this._idService);

  Result<DayTask> call(String title) {
    if (title.trim().isEmpty) {
      return const Err(ValidationFailure('Task cannot be empty.'));
    }
    final task = DayTask(id: _idService.newId(), title: title.trim());
    _repository.addTask(task);
    return Ok(task);
  }
}

class AddBook {
  final MindRepository _repository;
  final IdService _idService;

  const AddBook(this._repository, this._idService);

  Result<Book> call({
    required String title,
    String author = '',
    int totalPages = 0,
  }) {
    if (title.trim().isEmpty) {
      return const Err(ValidationFailure('Title cannot be empty.'));
    }
    final book = Book(
      id: _idService.newId(),
      title: title.trim(),
      author: author.trim(),
      totalPages: totalPages,
    );
    _repository.addBook(book);
    return Ok(book);
  }
}

class UpdateBookProgress {
  final MindRepository _repository;
  final EventBus _eventBus;
  final IdService _idService;
  final Clock _clock;

  const UpdateBookProgress(
    this._repository,
    this._eventBus,
    this._idService,
    this._clock,
  );

  void call(Book book, int page, {String userId = 'local'}) {
    final updated = book.withPage(page);
    _repository.updateBook(updated);
    _eventBus.publish(BookProgressEvent(
      id: _idService.newId(),
      userId: userId,
      occurredAt: _clock.now(),
      bookId: updated.id,
      currentPage: updated.currentPage,
    ));
  }
}

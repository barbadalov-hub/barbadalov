import 'dart:async';

import 'package:lifeos/features/mind/domain/entities/book.dart';
import 'package:lifeos/features/mind/domain/entities/day_task.dart';
import 'package:lifeos/features/mind/domain/entities/habit.dart';
import 'package:lifeos/features/mind/domain/repositories/mind_repository.dart';

class MindRepositoryImpl implements MindRepository {
  MindRepositoryImpl({
    List<Habit> seedHabits = const [],
    List<DayTask> seedTasks = const [],
    List<Book> seedBooks = const [],
    this.onHabitsChanged,
    this.onTasksChanged,
    this.onBooksChanged,
  })  : _habits = List.of(seedHabits),
        _tasks = List.of(seedTasks),
        _books = List.of(seedBooks);

  final List<Habit> _habits;
  final List<DayTask> _tasks;
  final List<Book> _books;
  final void Function(List<Habit> items)? onHabitsChanged;
  final void Function(List<DayTask> items)? onTasksChanged;
  final void Function(List<Book> items)? onBooksChanged;

  final StreamController<List<Habit>> _habitsController =
      StreamController<List<Habit>>.broadcast();
  final StreamController<List<DayTask>> _tasksController =
      StreamController<List<DayTask>>.broadcast();
  final StreamController<List<Book>> _booksController =
      StreamController<List<Book>>.broadcast();

  @override
  List<Habit> habits() => List.unmodifiable(_habits);

  @override
  void addHabit(Habit habit) {
    _habits.add(habit);
    _emitHabits();
    onHabitsChanged?.call(habits());
  }

  @override
  void toggleHabit(String id, DateTime day) {
    final i = _habits.indexWhere((h) => h.id == id);
    if (i == -1) return;
    _habits[i] = _habits[i].toggledOn(day);
    _emitHabits();
    onHabitsChanged?.call(habits());
  }

  @override
  Stream<List<Habit>> watchHabits() async* {
    yield habits();
    yield* _habitsController.stream;
  }

  @override
  List<DayTask> tasks() => List.unmodifiable(_tasks);

  @override
  void addTask(DayTask task) {
    _tasks.add(task);
    _emitTasks();
    onTasksChanged?.call(tasks());
  }

  @override
  void toggleTask(String id) {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i == -1) return;
    _tasks[i] = _tasks[i].toggle();
    _emitTasks();
    onTasksChanged?.call(tasks());
  }

  @override
  void clearCompletedTasks() {
    _tasks.removeWhere((t) => t.done);
    _emitTasks();
    onTasksChanged?.call(tasks());
  }

  @override
  Stream<List<DayTask>> watchTasks() async* {
    yield tasks();
    yield* _tasksController.stream;
  }

  @override
  List<Book> books() => List.unmodifiable(_books);

  @override
  void addBook(Book book) {
    _books.add(book);
    _emitBooks();
    onBooksChanged?.call(books());
  }

  @override
  void updateBook(Book book) {
    final i = _books.indexWhere((b) => b.id == book.id);
    if (i == -1) return;
    _books[i] = book;
    _emitBooks();
    onBooksChanged?.call(books());
  }

  @override
  Stream<List<Book>> watchBooks() async* {
    yield books();
    yield* _booksController.stream;
  }

  void _emitBooks() {
    if (!_booksController.isClosed) _booksController.add(books());
  }

  void _emitHabits() {
    if (!_habitsController.isClosed) _habitsController.add(habits());
  }

  void _emitTasks() {
    if (!_tasksController.isClosed) _tasksController.add(tasks());
  }

  Future<void> dispose() async {
    await _habitsController.close();
    await _tasksController.close();
    await _booksController.close();
  }
}

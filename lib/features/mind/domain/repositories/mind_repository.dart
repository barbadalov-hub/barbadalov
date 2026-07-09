import 'package:lifeos/features/mind/domain/entities/book.dart';
import 'package:lifeos/features/mind/domain/entities/day_task.dart';
import 'package:lifeos/features/mind/domain/entities/habit.dart';

abstract class MindRepository {
  // Habits
  List<Habit> habits();
  void addHabit(Habit habit);
  void toggleHabit(String id, DateTime day);
  Stream<List<Habit>> watchHabits();

  // Tasks
  List<DayTask> tasks();
  void addTask(DayTask task);
  void toggleTask(String id);
  void clearCompletedTasks();
  Stream<List<DayTask>> watchTasks();

  // Books / learning
  List<Book> books();
  void addBook(Book book);
  void updateBook(Book book);
  Stream<List<Book>> watchBooks();
}

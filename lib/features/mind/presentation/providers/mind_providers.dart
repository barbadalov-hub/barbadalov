import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/constants/app_constants.dart';
import 'package:lifeos/features/mind/application/mind_use_cases.dart';
import 'package:lifeos/features/mind/data/mind_repository_impl.dart';
import 'package:lifeos/features/mind/domain/achievements.dart';
import 'package:lifeos/features/mind/domain/entities/book.dart';
import 'package:lifeos/features/mind/domain/entities/day_task.dart';
import 'package:lifeos/features/mind/domain/entities/habit.dart';
import 'package:lifeos/features/mind/domain/repositories/mind_repository.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

final mindRepositoryProvider = Provider<MindRepository>((ref) {
  final store = ref.watch(jsonStoreProvider);
  final now = ref.watch(clockProvider).now();
  const habitsKey = 'mind.habits';
  const tasksKey = 'mind.tasks';
  const booksKey = 'mind.books';
  // Recompute each habit's streak / done-today against today, so a habit done
  // yesterday correctly shows as not-done today.
  final habits = [
    for (final h in store.loadList(habitsKey, Habit.fromJson,
        fallback:
            AppConstants.seedDemoData ? _defaultHabits(now) : const <Habit>[]))
      h.refreshedFor(now),
  ];
  final impl = MindRepositoryImpl(
    seedHabits: habits,
    seedTasks: store.loadList(tasksKey, DayTask.fromJson,
        fallback:
            AppConstants.seedDemoData ? _defaultTasks : const <DayTask>[]),
    seedBooks: store.loadList(booksKey, Book.fromJson,
        fallback: AppConstants.seedDemoData ? _defaultBooks : const <Book>[]),
    onHabitsChanged: (items) =>
        store.saveList(habitsKey, items, (h) => h.toJson()),
    onTasksChanged: (items) =>
        store.saveList(tasksKey, items, (t) => t.toJson()),
    onBooksChanged: (items) =>
        store.saveList(booksKey, items, (b) => b.toJson()),
  );
  ref.onDispose(impl.dispose);
  return impl;
});

List<Habit> _defaultHabits(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  List<DateTime> days(int count, {Set<int> skip = const {}}) => [
        for (var i = 0; i < count; i++)
          if (!skip.contains(i)) today.subtract(Duration(days: i)),
      ];
  return [
    Habit(
      id: 'h_read',
      name: 'Read 20 min',
      emoji: '📚',
      completedDates: days(5, skip: {2}),
    ),
    Habit(
      id: 'h_workout',
      name: 'Workout',
      emoji: '🏋️',
      targetPerWeek: 3,
      completedDates: days(12, skip: {1, 2, 5, 6, 9}),
    ),
    Habit(
      id: 'h_sugar',
      name: 'No sugar',
      emoji: '🍬',
      completedDates: days(3),
    ),
  ];
}

const _defaultTasks = <DayTask>[
  DayTask(id: 't1', title: 'Plan the week'),
  DayTask(id: 't2', title: 'Reply to emails', done: true),
];

final habitsProvider = StreamProvider<List<Habit>>((ref) {
  ref.watch(coreEngineProvider);
  return ref.watch(mindRepositoryProvider).watchHabits();
});

final tasksProvider = StreamProvider<List<DayTask>>((ref) {
  return ref.watch(mindRepositoryProvider).watchTasks();
});

final booksProvider = StreamProvider<List<Book>>((ref) {
  ref.watch(coreEngineProvider);
  return ref.watch(mindRepositoryProvider).watchBooks();
});

/// Gamification: milestone/consistency badges derived from the habit list.
final habitBadgesProvider = Provider<List<HabitBadge>>((ref) {
  final habits = ref.watch(habitsProvider).valueOrNull ?? const [];
  return const AchievementEngine().evaluate(habits);
});

/// Longest current habit streak, for the headline number.
final bestStreakProvider = Provider<int>((ref) {
  final habits = ref.watch(habitsProvider).valueOrNull ?? const [];
  return const AchievementEngine().bestStreak(habits);
});

/// Discipline pillar = share of habits done today.
final disciplineScoreProvider = Provider<int>((ref) {
  final habits = ref.watch(habitsProvider).valueOrNull ?? const [];
  if (habits.isEmpty) return 50;
  final done = habits.where((h) => h.doneToday).length;
  return (done / habits.length * 100).round();
});

/// Productivity pillar = share of today's tasks completed.
final productivityScoreProvider = Provider<int>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? const [];
  if (tasks.isEmpty) return 50;
  final done = tasks.where((t) => t.done).length;
  return (done / tasks.length * 100).round();
});

final toggleHabitProvider = Provider<ToggleHabit>((ref) => ToggleHabit(
      ref.watch(mindRepositoryProvider),
      ref.watch(eventBusProvider),
      ref.watch(idServiceProvider),
      ref.watch(clockProvider),
    ));

final toggleTaskProvider = Provider<ToggleTask>((ref) => ToggleTask(
      ref.watch(mindRepositoryProvider),
      ref.watch(eventBusProvider),
      ref.watch(idServiceProvider),
      ref.watch(clockProvider),
    ));

final addTaskProvider = Provider<AddTask>((ref) =>
    AddTask(ref.watch(mindRepositoryProvider), ref.watch(idServiceProvider)));

final addHabitProvider = Provider<AddHabit>((ref) =>
    AddHabit(ref.watch(mindRepositoryProvider), ref.watch(idServiceProvider)));

final addBookProvider = Provider<AddBook>((ref) =>
    AddBook(ref.watch(mindRepositoryProvider), ref.watch(idServiceProvider)));

final updateBookProgressProvider = Provider<UpdateBookProgress>((ref) =>
    UpdateBookProgress(
      ref.watch(mindRepositoryProvider),
      ref.watch(eventBusProvider),
      ref.watch(idServiceProvider),
      ref.watch(clockProvider),
    ));

const _defaultBooks = <Book>[
  Book(
    id: 'seed_book_atomic',
    title: 'Atomic Habits',
    author: 'James Clear',
    totalPages: 320,
    currentPage: 96,
  ),
  Book(
    id: 'seed_book_deep',
    title: 'Deep Work',
    author: 'Cal Newport',
    totalPages: 296,
    currentPage: 40,
  ),
];

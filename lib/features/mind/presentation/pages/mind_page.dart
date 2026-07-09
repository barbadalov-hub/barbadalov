import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/features/mind/domain/achievements.dart';
import 'package:lifeos/features/mind/domain/book_recommendations.dart';
import 'package:lifeos/features/mind/domain/entities/book.dart';
import 'package:lifeos/features/mind/presentation/pages/habit_detail_page.dart';
import 'package:lifeos/features/mind/presentation/providers/mind_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/widgets/animated_backdrop.dart';
import 'package:lifeos/shared/widgets/gradient_card.dart';
import 'package:lifeos/shared/widgets/section_card.dart';

class MindPage extends ConsumerWidget {
  const MindPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final tasks = ref.watch(tasksProvider);
    final books = ref.watch(booksProvider);
    final now = ref.watch(clockProvider).now();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('mind.title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTaskDialog(context, ref),
        icon: const Icon(Icons.add_task),
        label: Text(context.tr('mind.task')),
      ),
      body: AnimatedBackdrop(
        style: BackdropStyle.orbs,
        color: LifeGradients.mind.first,
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _AchievementsCard(),
          const SizedBox(height: 12),
          const _FocusTimerCard(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('mind.habits'),
                  style: Theme.of(context).textTheme.titleLarge),
              IconButton.filledTonal(
                onPressed: () => _addHabitDialog(context, ref),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          habits.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (list) => Column(
              children: [
                for (final h in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => HabitDetailPage(habitId: h.id)),
                    ),
                    leading:
                        Text(h.emoji, style: const TextStyle(fontSize: 22)),
                    title: Text(h.name),
                    subtitle: Text(
                      h.isFlexible
                          ? context.trp('habit.weekProgress', {
                              'n': h.completionsThisWeek(now),
                              'target': h.targetPerWeek,
                            })
                          : context.trp('mind.dayStreak', {'n': h.streak}),
                    ),
                    trailing: IconButton(
                      icon: Icon(h.doneToday
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked),
                      color: h.doneToday
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      onPressed: () => ref.read(toggleHabitProvider).call(h),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(context.tr('mind.todaysTasks'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          tasks.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(context.tr('mind.noTasks')),
                );
              }
              final done = list.where((t) => t.done).length;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: done / list.length,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('$done/${list.length}',
                          style: Theme.of(context).textTheme.labelMedium),
                      if (done > 0)
                        TextButton(
                          onPressed: () =>
                              ref.read(mindRepositoryProvider).clearCompletedTasks(),
                          child: Text(context.tr('mind.clearDone')),
                        ),
                    ],
                  ),
                  for (final t in list)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: t.done,
                      onChanged: (_) => ref.read(toggleTaskProvider).call(t),
                      title: Text(
                        t.title,
                        style: TextStyle(
                          decoration: t.done
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('mind.books'),
                  style: Theme.of(context).textTheme.titleLarge),
              IconButton.filledTonal(
                onPressed: () => _addBookDialog(context, ref),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          books.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (list) {
              if (list.isEmpty) {
                return Text(context.tr('mind.noBooks'));
              }
              return Column(
                children: [
                  for (final b in list)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          const Text('📖', style: TextStyle(fontSize: 22)),
                      title: Text(b.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (b.author.isNotEmpty)
                            Text(b.author,
                                style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                                value: b.progress, minHeight: 6),
                          ),
                        ],
                      ),
                      trailing: Text('${b.currentPage}/${b.totalPages}'),
                      onTap: () => _updateBookDialog(context, ref, b),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const _ReadingStatsCard(),
          const SizedBox(height: 20),
          const _RecommendedBooks(),
          const SizedBox(height: 80),
        ],
        ),
      ),
    );
  }

  Future<void> _addBookDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final pagesController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('mind.newBook')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: ctx.tr('mind.bookTitle')),
            ),
            TextField(
              controller: authorController,
              decoration: InputDecoration(labelText: ctx.tr('mind.author')),
            ),
            TextField(
              controller: pagesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: ctx.tr('mind.pages')),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr('common.add'))),
        ],
      ),
    );
    if (ok != true) return;
    ref.read(addBookProvider).call(
          title: titleController.text,
          author: authorController.text,
          totalPages: int.tryParse(pagesController.text) ?? 0,
        );
  }

  Future<void> _updateBookDialog(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) async {
    final controller = TextEditingController(text: '${book.currentPage}');
    final page = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(book.title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: ctx.tr('mind.currentPage')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text)),
            child: Text(ctx.tr('common.add')),
          ),
        ],
      ),
    );
    if (page == null) return;
    ref.read(updateBookProgressProvider).call(book, page);
  }

  Future<void> _addHabitDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    var emoji = '✅';
    var target = 7;
    const emojis = ['✅', '📚', '🏋️', '💧', '🧘', '🚭', '🥗', '🏃', '💤', '🧠'];
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(ctx.tr('habit.new')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration:
                      InputDecoration(labelText: ctx.tr('habit.name')),
                ),
                const SizedBox(height: 12),
                Text(ctx.tr('habit.icon'),
                    style: Theme.of(ctx).textTheme.bodySmall),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final e in emojis)
                      ChoiceChip(
                        label: Text(e, style: const TextStyle(fontSize: 18)),
                        selected: emoji == e,
                        onSelected: (_) => setState(() => emoji = e),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(ctx.trp('habit.perWeek', {'n': target}),
                    style: Theme.of(ctx).textTheme.bodySmall),
                Slider(
                  value: target.toDouble(),
                  min: 1,
                  max: 7,
                  divisions: 6,
                  label: '$target',
                  onChanged: (v) => setState(() => target = v.round()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(ctx.tr('common.cancel'))),
            FilledButton(
              onPressed: () {
                ref.read(addHabitProvider).call(
                      name: nameCtrl.text,
                      emoji: emoji,
                      targetPerWeek: target,
                    );
                Navigator.pop(ctx);
              },
              child: Text(ctx.tr('common.add')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTaskDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('mind.newTask')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: ctx.tr('mind.whatToDo')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(ctx.tr('common.add'))),
        ],
      ),
    );
    if (title == null || title.trim().isEmpty) return;
    ref.read(addTaskProvider).call(title);
  }
}

/// Gamified streaks & achievements: a headline best-streak number plus a wall
/// of milestone badges (earned in colour, locked greyed with progress).
class _AchievementsCard extends ConsumerWidget {
  const _AchievementsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final best = ref.watch(bestStreakProvider);
    final badges = ref.watch(habitBadgesProvider);
    final earned = badges.where((b) => b.earned).length;

    return GradientCard(
      colors: LifeGradients.mind,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.trp('ach.bestStreak', {'n': best}),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                    ),
                    Text(
                      context.trp('ach.earned', {
                        'n': earned,
                        'total': badges.length,
                      }),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (final b in badges) _badge(context, b)],
          ),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, HabitBadge b) {
    return Tooltip(
      message: b.earned
          ? context.tr(b.titleKey)
          : '${context.tr(b.titleKey)} · ${b.progress}/${b.goal}',
      child: Opacity(
        opacity: b.earned ? 1 : 0.35,
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: b.earned ? 0.25 : 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: b.earned ? 0.9 : 0.3),
              width: 1.5,
            ),
          ),
          child: Text(b.emoji, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }
}

/// A curated shelf of growth books; one tap adds a book to the reading list
/// (or shows a check if it is already there).
class _RecommendedBooks extends ConsumerWidget {
  const _RecommendedBooks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owned = {
      for (final b in ref.watch(booksProvider).valueOrNull ?? const [])
        b.title.toLowerCase(),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📚 ${context.tr('rec.title')}',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(context.tr('rec.sub'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                )),
        const SizedBox(height: 8),
        for (final idea in BookRecommendations.all)
          _ideaTile(context, ref, idea, owned.contains(idea.title.toLowerCase())),
      ],
    );
  }

  Widget _ideaTile(
      BuildContext context, WidgetRef ref, BookIdea idea, bool added) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Text('📗', style: TextStyle(fontSize: 26)),
        title: Text(idea.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(idea.author,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(context.tr(idea.whyKey),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    )),
          ],
        ),
        isThreeLine: true,
        trailing: added
            ? const Icon(Icons.check_circle, color: Color(0xFF2E9E6B))
            : IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: context.tr('rec.add'),
                onPressed: () {
                  ref.read(addBookProvider).call(
                        title: idea.title,
                        author: idea.author,
                        totalPages: idea.totalPages,
                      );
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                        content: Text(context
                            .trp('rec.added', {'title': idea.title}))));
                },
              ),
      ),
    );
  }
}

/// A Pomodoro focus timer — 25 min work / 5 min break — to pair with the
/// Deep Work theme. Plugin-free (an in-app countdown); counts sessions.
class _FocusTimerCard extends StatefulWidget {
  const _FocusTimerCard();

  @override
  State<_FocusTimerCard> createState() => _FocusTimerCardState();
}

class _FocusTimerCardState extends State<_FocusTimerCard> {
  static const _work = 25 * 60;
  static const _break = 5 * 60;
  int _remaining = _work;
  bool _running = false;
  bool _isBreak = false;
  int _sessions = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        HapticFeedback.mediumImpact();
        if (!_isBreak) _sessions++;
        _isBreak = !_isBreak;
        _remaining = _isBreak ? _break : _work;
      }
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _isBreak = false;
      _remaining = _work;
    });
  }

  String get _mmss {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      color: LifeGradients.mind.first.withValues(alpha: 0.12),
      child: Row(
        children: [
          Text(_isBreak ? '☕' : '🎯', style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isBreak ? context.tr('focus.break') : context.tr('focus.work'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(_mmss,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()])),
                if (_sessions > 0)
                  Text(context.trp('focus.sessions', {'n': _sessions}),
                      style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: _toggle,
            icon: Icon(_running ? Icons.pause : Icons.play_arrow),
          ),
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.stop),
          ),
        ],
      ),
    );
  }
}

/// Reading stats derived from the book list.
class _ReadingStatsCard extends ConsumerWidget {
  const _ReadingStatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider).valueOrNull ?? const [];
    if (books.isEmpty) return const SizedBox.shrink();
    final finished = books.where((b) => b.isFinished).length;
    final reading = books.length - finished;
    final pages = books.fold(0, (s, b) => s + b.currentPage);
    return SectionCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(context, '📖', '$reading', context.tr('read.reading')),
          _stat(context, '✅', '$finished', context.tr('read.finished')),
          _stat(context, '📄', '$pages', context.tr('read.pages')),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

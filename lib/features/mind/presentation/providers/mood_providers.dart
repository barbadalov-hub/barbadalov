import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/mind/domain/mood.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// The mood journal, chronological. One entry per day (upsert).
class MoodController extends Notifier<List<MoodEntry>> {
  static const _key = 'mind.mood';
  static const _cap = 400;

  @override
  List<MoodEntry> build() {
    final list = [
      ...ref.watch(jsonStoreProvider).loadList<MoodEntry>(
            _key,
            MoodEntry.fromJson,
            fallback: const [],
          ),
    ]..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  void log(MoodEntry entry) {
    final day = _dateOnly(entry.date);
    final next = [
      for (final e in state)
        if (_dateOnly(e.date) != day) e,
      entry,
    ]..sort((a, b) => a.date.compareTo(b.date));
    final trimmed = next.length > _cap ? next.sublist(next.length - _cap) : next;
    ref.read(jsonStoreProvider).saveList<MoodEntry>(
          _key,
          trimmed,
          (e) => e.toJson(),
        );
    state = trimmed;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

final moodLogProvider =
    NotifierProvider<MoodController, List<MoodEntry>>(MoodController.new);

final moodSummaryProvider = Provider<MoodSummary?>((ref) {
  return const MoodAnalyzer()
      .summarize(ref.watch(moodLogProvider), ref.watch(clockProvider).now());
});

/// Today's entry if it exists, so the form can pre-fill.
final todayMoodProvider = Provider<MoodEntry?>((ref) {
  final now = ref.watch(clockProvider).now();
  final today = DateTime(now.year, now.month, now.day);
  for (final e in ref.watch(moodLogProvider)) {
    if (DateTime(e.date.year, e.date.month, e.date.day) == today) return e;
  }
  return null;
});

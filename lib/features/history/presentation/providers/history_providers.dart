import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/health/domain/entities/health_day.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/features/history/application/snapshot_builder.dart';
import 'package:lifeos/features/history/domain/monthly_snapshot.dart';
import 'package:lifeos/features/mind/domain/mood.dart';
import 'package:lifeos/features/mind/presentation/providers/mood_providers.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// The persisted long-term archive of completed months (up to ~20 years).
class HistoryController extends Notifier<List<MonthlySnapshot>> {
  static const _key = 'history.months';
  static const _cap = 240;

  @override
  List<MonthlySnapshot> build() {
    return [
      ...ref.watch(jsonStoreProvider).loadList<MonthlySnapshot>(
            _key,
            MonthlySnapshot.fromJson,
            fallback: const [],
          ),
    ]..sort((a, b) => a.ym.compareTo(b.ym));
  }

  Map<int, MonthlySnapshot> get byYm => {for (final s in state) s.ym: s};

  void addAll(List<MonthlySnapshot> snapshots) {
    final map = byYm..addEntries(snapshots.map((s) => MapEntry(s.ym, s)));
    final next = map.values.toList()..sort((a, b) => a.ym.compareTo(b.ym));
    final trimmed =
        next.length > _cap ? next.sublist(next.length - _cap) : next;
    ref.read(jsonStoreProvider).saveList<MonthlySnapshot>(
          _key,
          trimmed,
          (s) => s.toJson(),
        );
    state = trimmed;
  }
}

final historyProvider =
    NotifierProvider<HistoryController, List<MonthlySnapshot>>(
        HistoryController.new);

int _nextYm(int ym) {
  final y = ym ~/ 100;
  final m = ym % 100;
  return m >= 12 ? (y + 1) * 100 + 1 : ym + 1;
}

/// Archives every completed month not yet stored. Kept alive by [HomeShell];
/// runs once per launch. From now on, each finished month is frozen so the
/// timeline grows over the years.
final historyArchiveServiceProvider = Provider<void>((ref) {
  Future.microtask(() {
    try {
      _archive(ref);
    } catch (_) {}
  });
});

typedef _Sources = ({
  List<Transaction> transactions,
  List<MoodEntry> moods,
  List<HealthDay> days,
  List<(DateTime, double)> weights,
});

_Sources _sources(Ref ref) {
  final txs = ref.read(transactionsProvider).valueOrNull ?? const <Transaction>[];
  final days = [...ref.read(healthHistoryProvider)];
  final today = ref.read(todayHealthProvider).valueOrNull;
  if (today != null) days.add(today);
  return (
    transactions: txs,
    moods: ref.read(moodLogProvider),
    days: days,
    weights: ref.read(weightHistoryProvider),
  );
}

void _archive(Ref ref) {
  final now = ref.read(clockProvider).now();
  final curYm = now.year * 100 + now.month;
  final s = _sources(ref);
  if (s.transactions.isEmpty && s.moods.isEmpty && s.days.isEmpty) return;

  // Earliest month we have any transaction for, clamped to 60 months back.
  var earliest = curYm;
  for (final t in s.transactions) {
    final ym = t.date.year * 100 + t.date.month;
    if (ym < earliest) earliest = ym;
  }
  final floor = _monthsBack(now, 60);
  if (earliest < floor) earliest = floor;

  final existing = ref.read(historyProvider.notifier).byYm;
  const builder = SnapshotBuilder();
  final toAdd = <MonthlySnapshot>[];
  var ym = earliest;
  while (ym < curYm) {
    if (!existing.containsKey(ym)) {
      final snap = builder.build(
        ym: ym,
        transactions: s.transactions,
        moods: s.moods,
        days: s.days,
        weights: s.weights,
      );
      if (snap.hasData) toAdd.add(snap);
    }
    ym = _nextYm(ym);
  }
  if (toAdd.isNotEmpty) ref.read(historyProvider.notifier).addAll(toAdd);
}

int _monthsBack(DateTime now, int months) {
  final total = now.year * 12 + (now.month - 1) - months;
  return (total ~/ 12) * 100 + (total % 12) + 1;
}

/// The timeline: archived months + the current month computed live, newest
/// first (only months that actually have data).
final timelineProvider = Provider<List<MonthlySnapshot>>((ref) {
  final now = ref.watch(clockProvider).now();
  final curYm = now.year * 100 + now.month;
  final s = _sources(ref);
  final live = const SnapshotBuilder().build(
    ym: curYm,
    transactions: s.transactions,
    moods: s.moods,
    days: s.days,
    weights: s.weights,
  );
  final map = {for (final x in ref.watch(historyProvider)) x.ym: x};
  map[curYm] = live;
  return map.values.where((x) => x.hasData).toList()
    ..sort((a, b) => b.ym.compareTo(a.ym));
});

/// "On this month, N years ago" — the most recent snapshot for the same month
/// in a previous year, for a Today flashback card.
final flashbackProvider = Provider<MonthlySnapshot?>((ref) {
  final now = ref.watch(clockProvider).now();
  final candidates = ref.watch(historyProvider)
      .where((s) => s.month == now.month && s.year < now.year && s.hasData)
      .toList()
    ..sort((a, b) => b.year.compareTo(a.year));
  return candidates.firstOrNull;
});

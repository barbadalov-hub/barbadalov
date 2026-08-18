import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/health/presentation/providers/activity_providers.dart';
import 'package:lifeos/features/health/presentation/providers/health_providers.dart';
import 'package:lifeos/features/mind/presentation/providers/mood_providers.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/features/telescope/domain/period_stats.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

/// How far out the telescope is currently zoomed.
final timeZoomProvider = StateProvider<TimeZoom>((_) => TimeZoom.d7);

/// The stats for the selected window, rebuilt whenever the zoom or any of the
/// underlying logs change.
final periodStatsProvider = Provider<PeriodStats>((ref) {
  final days = [...ref.watch(healthHistoryProvider)];
  final today = ref.watch(todayHealthProvider).valueOrNull;
  if (today != null) days.add(today);

  return const PeriodStatsBuilder().build(
    zoom: ref.watch(timeZoomProvider),
    now: ref.watch(clockProvider).now(),
    transactions: ref.watch(transactionsProvider).valueOrNull ?? const [],
    days: days,
    moods: ref.watch(moodLogProvider),
    activities: ref.watch(activitiesProvider),
  );
});

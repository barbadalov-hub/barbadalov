import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/i18n/locale_controller.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/notifications/domain/entities/app_notification.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_prefs.dart';
import 'package:lifeos/features/notifications/presentation/providers/notification_providers.dart';
import 'package:lifeos/features/wellness/domain/cycle.dart';
import 'package:lifeos/features/wellness/domain/cycle_log.dart';
import 'package:lifeos/features/wellness/domain/vitality.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

// --- Cycle (women) ---------------------------------------------------------

/// The saved cycle setup, or null until the questionnaire is completed.
class CycleController extends Notifier<CycleData?> {
  static const _key = 'wellness.cycle';

  @override
  CycleData? build() {
    final raw = ref.watch(keyValueStoreProvider).getString(_key);
    if (raw == null) return null;
    return ref.watch(jsonStoreProvider).loadObject(
          _key,
          CycleData.fromJson,
          fallback: CycleData(lastPeriodStart: ref.read(clockProvider).now()),
        );
  }

  void save(CycleData data) {
    ref.read(jsonStoreProvider).saveObject(_key, data, (d) => d.toJson());
    state = data;
  }

  /// Record that a new period started on [day] (defaults to today) — shifts the
  /// whole prediction forward.
  void logPeriodStart([DateTime? day]) {
    final start = day ?? ref.read(clockProvider).now();
    final current = state;
    save(current == null
        ? CycleData(lastPeriodStart: start)
        : current.copyWith(lastPeriodStart: start));
  }
}

final cycleProvider =
    NotifierProvider<CycleController, CycleData?>(CycleController.new);

/// Live prediction for today, or null when there's no setup yet.
final cyclePredictionProvider = Provider<CyclePrediction?>((ref) {
  final data = ref.watch(cycleProvider);
  if (data == null) return null;
  return const CyclePredictor().predict(data, ref.watch(clockProvider).now());
});

/// Fires a pre-period reminder 2 days, 1 day, and on the predicted day, telling
/// the user to pack whatever they use (pads/tampons/…). Deduped per cycle+lead
/// so each nudge lands once. Kept alive by [HomeShell]; adding it also pushes to
/// the phone and bumps the badge. Dormant for men / until the cycle is set up.
final cyclePeriodAlertServiceProvider = Provider<void>((ref) {
  void check() => Future.microtask(() {
        try {
          _checkPeriodAlert(ref);
        } catch (_) {}
      });

  check();
  ref.listen(cyclePredictionProvider, (_, __) => check());
});

const _periodAlertedKey = 'wellness.periodAlerted';

void _checkPeriodAlert(Ref ref) {
  if (!ref.read(notificationPrefsProvider).enabled('period')) return;
  final data = ref.read(cycleProvider);
  final pred = ref.read(cyclePredictionProvider);
  if (data == null || pred == null) return;

  final lead = pred.daysUntilNextPeriod;
  if (lead < 0 || lead > 2) return; // only within the 2-day lead-up

  final np = pred.nextPeriodStart;
  final cycleKey = '${np.year}-${np.month}-${np.day}';
  final key = 'period:$cycleKey:$lead';

  final store = ref.read(keyValueStoreProvider);
  final alerted = _loadStringSet(store, _periodAlertedKey);
  if (alerted.contains(key)) return;

  final lang = ref.read(localeProvider)?.languageCode ?? 'en';
  final t = AppLocalizations(lang);
  final bodyKey = switch (lead) {
    0 => 'cycle.alert.today',
    1 => 'cycle.alert.tomorrow',
    _ => 'cycle.alert.soon',
  };

  ref.read(notificationRepositoryProvider).add(AppNotification(
        id: key,
        tier: NotificationTier.important,
        titleKey: 'cycle.alert.title',
        bodyKey: bodyKey,
        params: {
          'n': lead,
          'emoji': data.protection.emoji,
          'product': t.tr(data.protection.labelKey),
        },
        createdAt: ref.read(clockProvider).now(),
      ));

  alerted.add(key);
  // Keep only this cycle's keys so the set stays small.
  final pruned = alerted.where((k) => k.contains(':$cycleKey:')).toList();
  store.setString(_periodAlertedKey, jsonEncode(pruned));
}

Set<String> _loadStringSet(KeyValueStore store, String key) {
  final raw = store.getString(key);
  if (raw == null) return <String>{};
  try {
    return {for (final e in jsonDecode(raw) as List) e as String};
  } catch (_) {
    return <String>{};
  }
}

// --- Cycle diary (symptoms + flow per day) ---------------------------------

class CycleLogController extends Notifier<List<CycleDayLog>> {
  static const _key = 'wellness.cycleLog';
  static const _cap = 400;

  @override
  List<CycleDayLog> build() {
    return [
      ...ref.watch(jsonStoreProvider).loadList<CycleDayLog>(
            _key,
            CycleDayLog.fromJson,
            fallback: const [],
          ),
    ]..sort((a, b) => a.date.compareTo(b.date));
  }

  void log(CycleDayLog entry) {
    final day = _dateOnly(entry.date);
    final next = [
      for (final e in state)
        if (_dateOnly(e.date) != day) e,
      if (!entry.isEmpty) entry,
    ]..sort((a, b) => a.date.compareTo(b.date));
    final trimmed = next.length > _cap ? next.sublist(next.length - _cap) : next;
    ref.read(jsonStoreProvider).saveList<CycleDayLog>(
          _key,
          trimmed,
          (e) => e.toJson(),
        );
    state = trimmed;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

final cycleLogProvider =
    NotifierProvider<CycleLogController, List<CycleDayLog>>(
        CycleLogController.new);

/// Today's diary entry, or null.
final todayCycleLogProvider = Provider<CycleDayLog?>((ref) {
  final now = ref.watch(clockProvider).now();
  final today = DateTime(now.year, now.month, now.day);
  for (final e in ref.watch(cycleLogProvider)) {
    if (DateTime(e.date.year, e.date.month, e.date.day) == today) return e;
  }
  return null;
});

// --- Vitality (men) --------------------------------------------------------

/// Chronological check-in history (one entry per day; newest kept on upsert).
class VitalityController extends Notifier<List<VitalityCheckin>> {
  static const _key = 'wellness.vitality';
  static const _cap = 180;

  @override
  List<VitalityCheckin> build() {
    final list = [
      ...ref.watch(jsonStoreProvider).loadList<VitalityCheckin>(
            _key,
            VitalityCheckin.fromJson,
            fallback: const [],
          ),
    ]..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// Add or replace today's check-in.
  void log(VitalityCheckin checkin) {
    final day = _dateOnly(checkin.date);
    final next = [
      for (final c in state)
        if (_dateOnly(c.date) != day) c,
      checkin,
    ]..sort((a, b) => a.date.compareTo(b.date));
    final trimmed = next.length > _cap ? next.sublist(next.length - _cap) : next;
    ref.read(jsonStoreProvider).saveList<VitalityCheckin>(
          _key,
          trimmed,
          (c) => c.toJson(),
        );
    state = trimmed;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

final vitalityLogProvider =
    NotifierProvider<VitalityController, List<VitalityCheckin>>(
        VitalityController.new);

/// Rolling summary (score, week average, trend, streak, phase, tip).
final vitalitySummaryProvider = Provider<VitalitySummary?>((ref) {
  final log = ref.watch(vitalityLogProvider);
  return const VitalityAnalyzer()
      .summarize(log, ref.watch(clockProvider).now());
});

/// Today's check-in if one exists (so the form can pre-fill).
final todayCheckinProvider = Provider<VitalityCheckin?>((ref) {
  final now = ref.watch(clockProvider).now();
  final today = DateTime(now.year, now.month, now.day);
  for (final c in ref.watch(vitalityLogProvider)) {
    if (DateTime(c.date.year, c.date.month, c.date.day) == today) return c;
  }
  return null;
});

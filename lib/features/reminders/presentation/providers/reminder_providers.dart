import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/i18n/locale_controller.dart';
import 'package:lifeos/core/services/notification_gateway.dart';
import 'package:lifeos/features/mind/presentation/providers/mood_providers.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/features/profile/domain/entities/user_profile.dart';
import 'package:lifeos/features/profile/presentation/providers/profile_providers.dart';
import 'package:lifeos/features/reminders/domain/entities/reminder.dart';
import 'package:lifeos/features/reminders/domain/reminder_suggester.dart';
import 'package:lifeos/features/reports/presentation/providers/report_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:uuid/uuid.dart';

/// Stored list of the user's daily reminders. Every mutation persists the list
/// and re-syncs the OS schedule so phone notifications stay in step (no-op on
/// web/desktop, where the in-app badge is the cue instead).
class ReminderController extends Notifier<List<Reminder>> {
  static const _key = 'reminders.list';
  static const _uuid = Uuid();

  @override
  List<Reminder> build() {
    final list = ref.watch(jsonStoreProvider).loadList<Reminder>(
          _key,
          Reminder.fromJson,
          fallback: const [],
        );
    // Re-arm the OS schedule on every launch: keeps daily times correct across
    // reboots and DST changes. Fire-and-forget.
    Future.microtask(_resyncAll);
    return list;
  }

  void add({
    required ReminderKind kind,
    String customLabel = '',
    required int hour,
    required int minute,
  }) {
    final reminder = Reminder(
      id: _uuid.v4(),
      kind: kind,
      customLabel: customLabel,
      hour: hour,
      minute: minute,
    );
    _persist([...state, reminder]);
    _schedule(reminder);
  }

  void toggle(String id) {
    final next = [
      for (final r in state)
        if (r.id == id) r.copyWith(enabled: !r.enabled) else r,
    ];
    _persist(next);
    final changed = next.firstWhere((r) => r.id == id);
    if (changed.enabled) {
      _schedule(changed);
    } else {
      notificationGateway.cancel(changed.notificationId);
    }
  }

  void remove(String id) {
    final gone = state.where((r) => r.id == id).toList();
    _persist(state.where((r) => r.id != id).toList());
    for (final r in gone) {
      notificationGateway.cancel(r.notificationId);
    }
  }

  /// Turn every reminder on or off at once.
  void setAllEnabled(bool enabled) {
    _persist([for (final r in state) r.copyWith(enabled: enabled)]);
    for (final r in state) {
      if (enabled) {
        _schedule(r);
      } else {
        notificationGateway.cancel(r.notificationId);
      }
    }
  }

  void _persist(List<Reminder> next) {
    ref.read(jsonStoreProvider).saveList<Reminder>(
          _key,
          next,
          (r) => r.toJson(),
        );
    state = next;
  }

  void _resyncAll() {
    for (final r in state) {
      if (r.enabled) {
        _schedule(r);
      } else {
        notificationGateway.cancel(r.notificationId);
      }
    }
  }

  void _schedule(Reminder r) {
    final lang = ref.read(localeProvider)?.languageCode ?? 'en';
    final t = AppLocalizations(lang);
    final body =
        r.kind == ReminderKind.custom ? r.customLabel : t.tr(r.kind.labelKey);
    notificationGateway.scheduleDaily(
      id: r.notificationId,
      title: t.tr('reminder.fire.title'),
      body: body.isEmpty ? t.tr('reminder.fire.title') : body,
      hour: r.hour,
      minute: r.minute,
    );
  }
}

final remindersProvider =
    NotifierProvider<ReminderController, List<Reminder>>(
        ReminderController.new);

/// Data-driven reminder suggestions: watches sleep/water/mood/budget signals and
/// proposes helpful daily reminders the user doesn't already have.
final reminderSuggestionsProvider = Provider<List<ReminderKind>>((ref) {
  final report = ref.watch(weeklyReportProvider);
  final budget = ref.watch(currentBudgetProvider);
  final moods = ref.watch(moodLogProvider);
  final now = ref.watch(clockProvider).now();

  final lastMood = moods.isEmpty
      ? null
      : moods.map((m) => m.date).reduce((a, b) => a.isAfter(b) ? a : b);
  final moodRecent =
      lastMood != null && now.difference(lastMood).inDays <= 3;

  final existing = {for (final r in ref.watch(remindersProvider)) r.kind};
  final goal = ref.watch(profileProvider)?.goal;

  return suggestReminderKinds(
    ReminderSuggestionInputs(
      avgSleep: report.avgSleep,
      avgWater: report.avgWater,
      moodLoggedRecently: moodRecent,
      overBudget: budget.isOverspent,
      weightLossGoal: goal == FitnessGoal.lose,
    ),
    existing,
  );
});

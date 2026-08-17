import 'package:lifeos/features/rooms/domain/life_room.dart';

/// The one-tap offer printed on the featured cover.
enum AttentionAction {
  /// Adds a glass of water there and then — the screen never changes.
  drinkGlass,

  /// Ticks off the single habit still open today, by name.
  tickLastHabit,

  /// Opens the room. Still worth a chip: the label says what to do there.
  openRoom,
}

/// Why one room is being singled out on the home screen today.
///
/// The home screen is a magazine front page: it runs a lead story only when
/// there is news. [RoomAttentionBuilder] picks at most one — the most
/// neglected — and everything else stays a quiet spine.
class RoomAttention {
  final RoomId room;

  /// 0–100. Only used to pick a winner; never shown.
  final int urgency;

  /// The headline sentence, e.g. "Сон третий день короче нормы".
  final String reasonKey;
  final Map<String, Object> params;

  /// The figure to print big, when the room's usual hero is about something
  /// else. A headline about sleep over a huge step count reads as two
  /// unrelated statements; null means the room's own hero already fits.
  final String? heroKey;
  final Map<String, Object> heroParams;

  final AttentionAction action;

  /// Label for the action chip ("Записать сон", "+ стакан воды").
  final String actionKey;

  const RoomAttention({
    required this.room,
    required this.urgency,
    required this.reasonKey,
    required this.action,
    required this.actionKey,
    this.params = const {},
    this.heroKey,
    this.heroParams = const {},
  });
}

/// Everything the rules read, flattened so the decision is pure data in,
/// pure data out — and therefore cheap to test at any hour of any day.
class AttentionInput {
  /// Local hour, 0–23. Several rules only make sense late in the day: nobody
  /// has walked their steps by 9am, and saying so would be nagging.
  final int hour;

  final bool overspent;

  /// Nothing left in today's allowance.
  final bool nothingToSpend;

  final double sleepHours;
  final double sleepGoal;
  final int steps;
  final int stepGoal;
  final int waterMl;
  final int waterGoalMl;

  final int habitsTotal;
  final int habitsDone;

  /// Name of the last habit still open — set only when exactly one remains,
  /// because that is the only case a single tap can finish the day.
  final String? lastOpenHabit;

  final int goalsTotal;

  const AttentionInput({
    required this.hour,
    this.overspent = false,
    this.nothingToSpend = false,
    this.sleepHours = 0,
    this.sleepGoal = 8,
    this.steps = 0,
    this.stepGoal = 10000,
    this.waterMl = 0,
    this.waterGoalMl = 2000,
    this.habitsTotal = 0,
    this.habitsDone = 0,
    this.lastOpenHabit,
    this.goalsTotal = 0,
  });

  bool get nothingLoggedToday => steps == 0 && waterMl == 0 && sleepHours == 0;
}

class RoomAttentionBuilder {
  /// Below this, a room is not worth interrupting anyone for.
  static const threshold = 40;

  /// The lead story, or null when every room is in good shape.
  ///
  /// Returning null is a feature, not an empty state: a home screen with no
  /// headline is the app saying "today you owe nobody anything".
  static RoomAttention? build(AttentionInput i) {
    final candidates = <RoomAttention>[
      ..._money(i),
      ..._body(i),
      ..._mind(i),
      ..._goals(i),
    ]..sort((a, b) {
        final byUrgency = b.urgency.compareTo(a.urgency);
        // Ties fall back to reading order, so the choice is never arbitrary.
        return byUrgency != 0
            ? byUrgency
            : a.room.index.compareTo(b.room.index);
      });

    if (candidates.isEmpty) return null;
    final top = candidates.first;
    return top.urgency >= threshold ? top : null;
  }

  static Iterable<RoomAttention> _money(AttentionInput i) sync* {
    if (i.overspent) {
      yield const RoomAttention(
        room: RoomId.money,
        urgency: 92,
        reasonKey: 'attn.money.over',
        action: AttentionAction.openRoom,
        actionKey: 'attn.money.overAction',
      );
    } else if (i.nothingToSpend) {
      yield const RoomAttention(
        room: RoomId.money,
        urgency: 74,
        reasonKey: 'attn.money.dry',
        action: AttentionAction.openRoom,
        actionKey: 'attn.money.dryAction',
      );
    }
  }

  static Iterable<RoomAttention> _body(AttentionInput i) sync* {
    // A logged short night is a fact worth leading with. An *unlogged* night
    // is not evidence of anything, so it is handled by the blank-day rule.
    if (i.sleepHours > 0 && i.sleepHours < i.sleepGoal - 1) {
      yield RoomAttention(
        room: RoomId.body,
        urgency: 78,
        reasonKey: 'attn.body.sleep',
        params: {'h': i.sleepHours.toStringAsFixed(1)},
        heroKey: 'attn.hero.sleep',
        heroParams: {'h': i.sleepHours.toStringAsFixed(1)},
        action: AttentionAction.openRoom,
        actionKey: 'attn.body.sleepAction',
      );
    }
    if (i.nothingLoggedToday && i.hour >= 11) {
      yield const RoomAttention(
        room: RoomId.body,
        urgency: 58,
        reasonKey: 'attn.body.blank',
        action: AttentionAction.openRoom,
        actionKey: 'attn.body.blankAction',
      );
    }
    if (i.waterMl < i.waterGoalMl * 0.5 && i.hour >= 15) {
      yield RoomAttention(
        room: RoomId.body,
        urgency: 52,
        reasonKey: 'attn.body.water',
        heroKey: 'attn.hero.water',
        heroParams: {'l': (i.waterMl / 1000).toStringAsFixed(1)},
        // The only reason worth leading with that a single tap actually fixes.
        action: AttentionAction.drinkGlass,
        actionKey: 'attn.body.waterAction',
      );
    }
    if (i.steps < i.stepGoal * 0.4 && i.hour >= 19) {
      yield RoomAttention(
        room: RoomId.body,
        urgency: 48,
        reasonKey: 'attn.body.steps',
        params: {'n': i.stepGoal - i.steps},
        action: AttentionAction.openRoom,
        actionKey: 'attn.body.stepsAction',
      );
    }
  }

  static Iterable<RoomAttention> _mind(AttentionInput i) sync* {
    if (i.habitsTotal == 0) return;
    final left = i.habitsTotal - i.habitsDone;
    if (left <= 0) return;

    if (i.habitsDone == 0 && i.hour >= 13) {
      yield const RoomAttention(
        room: RoomId.mind,
        urgency: 62,
        reasonKey: 'attn.mind.none',
        action: AttentionAction.openRoom,
        actionKey: 'attn.mind.noneAction',
      );
    }
    // One habit left in the evening is the cheapest win the app can offer:
    // a single tap closes the whole day.
    if (left == 1 && i.lastOpenHabit != null && i.hour >= 17) {
      yield RoomAttention(
        room: RoomId.mind,
        urgency: 56,
        reasonKey: 'attn.mind.one',
        params: {'name': i.lastOpenHabit!},
        action: AttentionAction.tickLastHabit,
        actionKey: 'attn.mind.oneAction',
      );
    }
    if (left > 1 && i.hour >= 19) {
      yield RoomAttention(
        room: RoomId.mind,
        urgency: 50,
        reasonKey: 'attn.mind.left',
        params: {'n': left},
        action: AttentionAction.openRoom,
        actionKey: 'attn.mind.leftAction',
      );
    }
  }

  static Iterable<RoomAttention> _goals(AttentionInput i) sync* {
    // Deliberately the weakest signal in the app: an invitation, not a debt.
    // It only ever leads on a day where nothing is actually wrong.
    if (i.goalsTotal == 0) {
      yield const RoomAttention(
        room: RoomId.goals,
        urgency: 44,
        reasonKey: 'attn.goals.none',
        action: AttentionAction.openRoom,
        actionKey: 'attn.goals.noneAction',
      );
    }
  }
}

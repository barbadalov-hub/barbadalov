import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/rooms/domain/life_room.dart';
import 'package:lifeos/features/rooms/domain/room_attention.dart';

/// This rule decides what the home screen shouts about every morning, so it is
/// worth pinning down hard: which room wins, and — just as important — when
/// nobody wins and the app stays quiet.
void main() {
  group('picks the room that needs you', () {
    test('going over budget outranks everything else', () {
      final lead = RoomAttentionBuilder.build(const AttentionInput(
        hour: 20,
        overspent: true,
        sleepHours: 4, // also bad, but money is worse
        habitsTotal: 3,
        habitsDone: 0,
      ));
      expect(lead?.room, RoomId.money);
      expect(lead?.reasonKey, 'attn.money.over');
    });

    test('a short logged night leads over open habits', () {
      final lead = RoomAttentionBuilder.build(const AttentionInput(
        hour: 20,
        sleepHours: 5.5,
        sleepGoal: 8,
        habitsTotal: 3,
        habitsDone: 1,
      ));
      expect(lead?.room, RoomId.body);
      expect(lead?.params['h'], '5.5');
      // The big figure has to be the one the headline is about — a step count
      // printed over a sentence about sleep reads as two unrelated statements.
      expect(lead?.heroKey, 'attn.hero.sleep');
      expect(lead?.heroParams['h'], '5.5');
    });

    test('an unlogged night is not treated as a short one', () {
      // Zero sleep means "not recorded", never "slept nothing" — accusing
      // someone of a 0-hour night is the kind of nonsense that kills trust.
      final lead = RoomAttentionBuilder.build(const AttentionInput(
        hour: 9,
        sleepHours: 0,
        steps: 4000, // something logged, so the blank-day rule stays out
      ));
      expect(lead?.reasonKey, isNot('attn.body.sleep'));
    });
  });

  group('stays quiet when it should', () {
    test('a good day lights nothing at all', () {
      final lead = RoomAttentionBuilder.build(const AttentionInput(
        hour: 21,
        sleepHours: 8,
        steps: 11000,
        waterMl: 2200,
        habitsTotal: 3,
        habitsDone: 3,
        goalsTotal: 2,
      ));
      expect(lead, isNull, reason: 'nothing is wrong, so there is no headline');
    });

    test('morning does not nag about steps or habits', () {
      // Nobody has walked their steps by 8am. Saying so is nagging, not help.
      final lead = RoomAttentionBuilder.build(const AttentionInput(
        hour: 8,
        sleepHours: 8,
        steps: 300,
        waterMl: 0,
        habitsTotal: 4,
        habitsDone: 0,
        goalsTotal: 1,
      ));
      expect(lead, isNull);
    });

    test('the same day in the evening does speak up', () {
      final lead = RoomAttentionBuilder.build(const AttentionInput(
        hour: 20,
        sleepHours: 8,
        steps: 300,
        waterMl: 0,
        habitsTotal: 4,
        habitsDone: 0,
        goalsTotal: 1,
      ));
      expect(lead?.room, RoomId.mind);
    });
  });

  group('offers a fix that matches the reason', () {
    test('thirst is fixed in place, not by opening a screen', () {
      final lead = RoomAttentionBuilder.build(const AttentionInput(
        hour: 16,
        sleepHours: 8,
        steps: 9000,
        waterMl: 200,
        waterGoalMl: 2000,
        goalsTotal: 1,
      ));
      expect(lead?.room, RoomId.body);
      expect(lead?.action, AttentionAction.drinkGlass);
    });

    test('one habit left is a single tap, not a trip to the room', () {
      final lead = RoomAttentionBuilder.build(const AttentionInput(
        hour: 19,
        sleepHours: 8,
        steps: 9000,
        waterMl: 2000,
        habitsTotal: 3,
        habitsDone: 2,
        lastOpenHabit: 'Чтение',
        goalsTotal: 1,
      ));
      expect(lead?.action, AttentionAction.tickLastHabit);
      expect(lead?.params['name'], 'Чтение');
    });

    test('two habits left cannot be one tap, so it opens the room', () {
      final lead = RoomAttentionBuilder.build(const AttentionInput(
        hour: 20,
        sleepHours: 8,
        steps: 9000,
        waterMl: 2000,
        habitsTotal: 3,
        habitsDone: 1,
        goalsTotal: 1,
      ));
      expect(lead?.action, AttentionAction.openRoom);
      expect(lead?.params['n'], 2);
    });
  });

  test('a brand-new account is invited, not scolded', () {
    // Everything empty. The gentlest signal in the app should win.
    final lead = RoomAttentionBuilder.build(const AttentionInput(hour: 9));
    expect(lead?.room, RoomId.goals);
    expect(lead?.reasonKey, 'attn.goals.none');
  });

  test('ties never resolve at random', () {
    // Two rooms cannot currently tie, but the ordering must be defined if they
    // ever do — otherwise the home screen would flicker between them.
    final lead = RoomAttentionBuilder.build(const AttentionInput(
      hour: 23,
      overspent: true,
      nothingToSpend: true,
    ));
    expect(lead?.reasonKey, 'attn.money.over',
        reason: 'the stronger money signal must win over the weaker one');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/coach/domain/coach_engine.dart';

void main() {
  const engine = CoachEngine();

  group('classify', () {
    test('maps free text to intents (ru/uk/en)', () {
      expect(engine.classify('Как прошла неделя?'), CoachIntent.weekly);
      expect(engine.classify('сколько можно потратить сегодня'),
          CoachIntent.spend);
      expect(engine.classify('на чём сфокусироваться'), CoachIntent.focus);
      expect(engine.classify('как мой сон'), CoachIntent.sleep);
      expect(engine.classify('what can you do'), CoachIntent.help);
      expect(engine.classify('motivate me'), CoachIntent.motivate);
    });

    test('empty or nonsense is unknown', () {
      expect(engine.classify(''), CoachIntent.unknown);
      expect(engine.classify('qwerty zxcv'), CoachIntent.unknown);
    });

    test('maps the new pillar questions', () {
      expect(engine.classify('сколько шагов я прошёл'), CoachIntent.steps);
      expect(engine.classify('пью ли я достаточно воды'), CoachIntent.water);
      expect(engine.classify('как мои привычки'), CoachIntent.habits);
      expect(engine.classify('как мои цели'), CoachIntent.goals);
    });
  });

  group('reply', () {
    test('greeting adapts to whether a name is known', () {
      expect(engine.reply(CoachIntent.greeting, const CoachContext()).messageKey,
          'coach.reply.greetingAnon');
      expect(
        engine
            .reply(CoachIntent.greeting, const CoachContext(name: 'Arkadiy'))
            .messageKey,
        'coach.reply.greeting',
      );
    });

    test('sleep advice depends on hours', () {
      expect(engine.reply(CoachIntent.sleep, const CoachContext()).messageKey,
          'coach.reply.sleepNone');
      expect(
          engine
              .reply(CoachIntent.sleep, const CoachContext(avgSleep: 5.5))
              .messageKey,
          'coach.reply.sleepLow');
      expect(
          engine
              .reply(CoachIntent.sleep, const CoachContext(avgSleep: 8))
              .messageKey,
          'coach.reply.sleepOk');
    });

    test('focus targets the weakest pillar, or praises balance', () {
      const weakHealth = CoachContext(
          finance: 80, health: 30, discipline: 75, productivity: 70);
      expect(engine.reply(CoachIntent.focus, weakHealth).messageKey,
          'coach.reply.focus.health');

      const strong = CoachContext(
          finance: 80, health: 82, discipline: 90, productivity: 75);
      expect(engine.reply(CoachIntent.focus, strong).messageKey,
          'coach.reply.focus.allgood');
    });

    test('weekly includes the top category only when present', () {
      expect(
          engine.reply(CoachIntent.weekly, const CoachContext()).messageKey,
          'coach.reply.weeklyNoCat');
      final r = engine.reply(
          CoachIntent.weekly, const CoachContext(topCatName: 'Food'));
      expect(r.messageKey, 'coach.reply.weekly');
      expect(r.params['top'], 'Food');
    });

    test('motivate rotates over five variants by seed', () {
      expect(engine.reply(CoachIntent.motivate, const CoachContext(seed: 7)).messageKey,
          'coach.reply.motivate.2');
    });

    test('motivate praises a live logging streak instead of a generic quote',
        () {
      final r = engine.reply(
          CoachIntent.motivate, const CoachContext(loggingStreak: 5));
      expect(r.messageKey, 'coach.reply.streakPraise');
      expect(r.params['n'], 5);
      // Below the threshold the rotation stays.
      expect(
          engine
              .reply(CoachIntent.motivate,
                  const CoachContext(loggingStreak: 2, seed: 0))
              .messageKey,
          'coach.reply.motivate.0');
    });

    test('water advice depends on glasses; steps/habits handle no data', () {
      expect(engine.reply(CoachIntent.water, const CoachContext()).messageKey,
          'coach.reply.waterNone');
      expect(
          engine.reply(CoachIntent.water, const CoachContext(avgWater: 3)).messageKey,
          'coach.reply.waterLow');
      expect(
          engine.reply(CoachIntent.water, const CoachContext(avgWater: 8)).messageKey,
          'coach.reply.waterOk');
      expect(engine.reply(CoachIntent.steps, const CoachContext()).messageKey,
          'coach.reply.stepsNone');
      expect(engine.reply(CoachIntent.habits, const CoachContext()).messageKey,
          'coach.reply.habitsNone');
      expect(
          engine
              .reply(CoachIntent.habits,
                  const CoachContext(habitsDone: 2, habitsTotal: 3))
              .messageKey,
          'coach.reply.habits');
    });

    test('insight cites the finding, or nudges when none', () {
      expect(
          engine.reply(CoachIntent.insight, const CoachContext()).messageKey,
          'coach.reply.insightNone');
      final r = engine.reply(CoachIntent.insight,
          const CoachContext(insightSentence: 'more steps, better mood'));
      expect(r.messageKey, 'coach.reply.insight');
      expect(r.params['finding'], 'more steps, better mood');
    });
  });

  group('classify insight', () {
    test('recognises pattern questions in ru/en', () {
      expect(engine.classify('есть закономерности?'), CoachIntent.insight);
      expect(engine.classify('any patterns'), CoachIntent.insight);
    });
  });

  group('suggestOfTheDay', () {
    test('prioritises low sleep, then insights, then weak pillar', () {
      expect(engine.suggestOfTheDay(const CoachContext(avgSleep: 5)),
          CoachIntent.sleep);
      expect(
          engine.suggestOfTheDay(
              const CoachContext(avgSleep: 8, insightSentence: 'x')),
          CoachIntent.insight);
      expect(
          engine.suggestOfTheDay(const CoachContext(
              avgSleep: 8, finance: 30, health: 80, discipline: 80, productivity: 80)),
          CoachIntent.focus);
    });

    test('falls back to logging mood, then motivation', () {
      expect(
          engine.suggestOfTheDay(const CoachContext(
              avgSleep: 8,
              finance: 80,
              health: 80,
              discipline: 80,
              productivity: 80,
              moodEntries: 0)),
          CoachIntent.mood);
      expect(
          engine.suggestOfTheDay(const CoachContext(
              avgSleep: 8,
              finance: 80,
              health: 80,
              discipline: 80,
              productivity: 80,
              moodEntries: 5)),
          CoachIntent.motivate);
    });
  });
}

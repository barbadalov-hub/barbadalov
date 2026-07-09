/// What the user is asking the AI life coach.
enum CoachIntent {
  greeting,
  weekly,
  spend,
  focus,
  sleep,
  mood,
  steps,
  water,
  habits,
  goals,
  money,
  insight,
  motivate,
  help,
  unknown,
}

/// A snapshot of the user's data the coach reasons over. Money figures arrive
/// pre-formatted (currency formatting needs a locale) so the engine stays pure.
class CoachContext {
  final String name;
  final int lifeScore;
  final int finance;
  final int health;
  final int discipline;
  final int productivity;

  final String netStr;
  final String safeTodayStr;
  final String availableStr;
  final String goalsSavedStr;
  final String topCatName;

  final double avgSleep;
  final double avgWater;
  final double avgMood;
  final double avgMood30;
  final int moodEntries;
  final int avgSteps;
  final int bestStreak;
  final int loggingStreak;
  final int habitsDone;
  final int habitsTotal;
  final int goalsCompleted;
  final int seed;

  /// A pre-localized "patterns" sentence from Insights (e.g. "you feel better on
  /// days you sleep more"), or '' when there's no strong correlation yet.
  final String insightSentence;

  const CoachContext({
    this.name = '',
    this.lifeScore = 50,
    this.finance = 50,
    this.health = 50,
    this.discipline = 50,
    this.productivity = 50,
    this.netStr = '',
    this.safeTodayStr = '',
    this.availableStr = '',
    this.goalsSavedStr = '',
    this.topCatName = '',
    this.avgSleep = 0,
    this.avgWater = 0,
    this.avgMood = 0,
    this.avgMood30 = 0,
    this.moodEntries = 0,
    this.avgSteps = 0,
    this.bestStreak = 0,
    this.loggingStreak = 0,
    this.habitsDone = 0,
    this.habitsTotal = 0,
    this.goalsCompleted = 0,
    this.seed = 0,
    this.insightSentence = '',
  });
}

/// A coach message to render: an i18n key plus params resolved by the UI.
class CoachReply {
  final String messageKey;
  final Map<String, Object> params;
  const CoachReply(this.messageKey, [this.params = const {}]);
}

/// A rule-based conversational coach. Classifies free text into a [CoachIntent]
/// and produces a data-driven [CoachReply]. Pure and unit-tested; all wording
/// lives in i18n so it stays multilingual.
class CoachEngine {
  const CoachEngine();

  /// The quick-question chips offered in the UI.
  static const suggestions = [
    CoachIntent.weekly,
    CoachIntent.spend,
    CoachIntent.focus,
    CoachIntent.sleep,
    CoachIntent.mood,
    CoachIntent.steps,
    CoachIntent.water,
    CoachIntent.habits,
    CoachIntent.goals,
    CoachIntent.money,
    CoachIntent.insight,
    CoachIntent.motivate,
    CoachIntent.help,
  ];

  /// The one proactive tip to surface unprompted (e.g. on Today), chosen from
  /// the most actionable signal in [c].
  CoachIntent suggestOfTheDay(CoachContext c) {
    if (c.avgSleep > 0 && c.avgSleep < 7) return CoachIntent.sleep;
    if (c.insightSentence.isNotEmpty) return CoachIntent.insight;
    final weakest = [c.finance, c.health, c.discipline, c.productivity]
        .reduce((a, b) => a < b ? a : b);
    if (weakest < 50) return CoachIntent.focus;
    if (c.moodEntries == 0) return CoachIntent.mood;
    return CoachIntent.motivate;
  }

  static const _keywords = <CoachIntent, List<String>>{
    CoachIntent.help: ['help', 'can you', 'what can', 'помощь', 'умеешь', 'что ты', 'команд', 'можешь', 'допомог', 'вмієш'],
    CoachIntent.weekly: ['week', 'недел', 'тижд', 'как дела', 'how am i', 'итог', 'прошл'],
    CoachIntent.spend: ['afford', 'потрат', 'можно ли', 'spend', 'трат', 'витрат', 'купить', 'позвол'],
    CoachIntent.sleep: ['sleep', 'сон', 'сплю', 'спати', 'высып', 'высп'],
    CoachIntent.mood: ['mood', 'настроен', 'настрій', 'чувств', 'emotion'],
    CoachIntent.steps: ['step', 'шаг', 'ходь', 'прош', 'крок', 'walk', 'актив'],
    CoachIntent.water: ['water', 'вод', 'пить', 'drink', 'пити', 'гідрат'],
    CoachIntent.habits: ['habit', 'привыч', 'звич', 'дисциплин', 'рутин'],
    CoachIntent.goals: ['goal', 'цел', 'мечт', 'ціл', 'dream'],
    CoachIntent.money: ['money', 'деньг', 'гроші', 'бюджет', 'budget', 'сбереж', 'накоп', 'сэконом', 'финанс', 'фінанс'],
    CoachIntent.insight: ['pattern', 'закономерн', 'связ', 'инсайт', 'insight', 'зв’яз', 'залежн'],
    CoachIntent.focus: ['focus', 'фокус', 'сфокус', 'на чём', 'на чем', 'priorit', 'что делать', 'важно'],
    CoachIntent.motivate: ['motiv', 'мотив', 'вдохнов', 'подбадр', 'поддерж', 'надихн'],
    CoachIntent.greeting: ['hello', 'привет', 'прив', 'здравств', 'вітаю', 'добрый', 'доброго', 'hi'],
  };

  /// Priority order: more specific intents win over greetings.
  static const _priority = [
    CoachIntent.help,
    CoachIntent.weekly,
    CoachIntent.spend,
    CoachIntent.sleep,
    CoachIntent.mood,
    CoachIntent.steps,
    CoachIntent.water,
    CoachIntent.habits,
    CoachIntent.goals,
    CoachIntent.insight,
    CoachIntent.money,
    CoachIntent.focus,
    CoachIntent.motivate,
    CoachIntent.greeting,
  ];

  CoachIntent classify(String text) {
    final t = text.toLowerCase().trim();
    if (t.isEmpty) return CoachIntent.unknown;
    for (final intent in _priority) {
      for (final kw in _keywords[intent]!) {
        if (t.contains(kw)) return intent;
      }
    }
    return CoachIntent.unknown;
  }

  CoachReply reply(CoachIntent intent, CoachContext c) {
    switch (intent) {
      case CoachIntent.greeting:
        return c.name.isEmpty
            ? const CoachReply('coach.reply.greetingAnon')
            : CoachReply('coach.reply.greeting', {'name': c.name});

      case CoachIntent.help:
        return const CoachReply('coach.reply.help');

      case CoachIntent.weekly:
        final params = {
          'net': c.netStr,
          'sleep': c.avgSleep.toStringAsFixed(1),
          'streak': c.bestStreak,
          'habits': '${c.habitsDone}/${c.habitsTotal}',
        };
        return c.topCatName.isEmpty
            ? CoachReply('coach.reply.weeklyNoCat', params)
            : CoachReply('coach.reply.weekly', {...params, 'top': c.topCatName});

      case CoachIntent.spend:
        return CoachReply('coach.reply.spend', {
          'safe': c.safeTodayStr,
          'avail': c.availableStr,
        });

      case CoachIntent.focus:
        final pillars = {
          'finance': c.finance,
          'health': c.health,
          'discipline': c.discipline,
          'productivity': c.productivity,
        };
        final weakest =
            pillars.entries.reduce((a, b) => a.value <= b.value ? a : b);
        if (weakest.value >= 70) {
          return const CoachReply('coach.reply.focus.allgood');
        }
        return CoachReply('coach.reply.focus.${weakest.key}');

      case CoachIntent.sleep:
        if (c.avgSleep <= 0) return const CoachReply('coach.reply.sleepNone');
        final key =
            c.avgSleep < 7 ? 'coach.reply.sleepLow' : 'coach.reply.sleepOk';
        return CoachReply(key, {'h': c.avgSleep.toStringAsFixed(1)});

      case CoachIntent.mood:
        if (c.moodEntries == 0) return const CoachReply('coach.reply.moodNone');
        return CoachReply('coach.reply.mood', {
          'm': c.avgMood.toStringAsFixed(1),
          'm30': c.avgMood30.toStringAsFixed(1),
        });

      case CoachIntent.steps:
        return c.avgSteps <= 0
            ? const CoachReply('coach.reply.stepsNone')
            : CoachReply('coach.reply.steps', {'n': c.avgSteps});

      case CoachIntent.water:
        if (c.avgWater <= 0) return const CoachReply('coach.reply.waterNone');
        final key =
            c.avgWater < 6 ? 'coach.reply.waterLow' : 'coach.reply.waterOk';
        return CoachReply(key, {'n': c.avgWater.toStringAsFixed(0)});

      case CoachIntent.habits:
        return c.habitsTotal == 0
            ? const CoachReply('coach.reply.habitsNone')
            : CoachReply('coach.reply.habits', {
                'done': c.habitsDone,
                'total': c.habitsTotal,
                'streak': c.bestStreak,
              });

      case CoachIntent.goals:
        return CoachReply('coach.reply.goals', {
          'saved': c.goalsSavedStr,
          'goals': c.goalsCompleted,
        });

      case CoachIntent.money:
        return CoachReply('coach.reply.money', {
          'saved': c.goalsSavedStr,
          'avail': c.availableStr,
          'goals': c.goalsCompleted,
        });

      case CoachIntent.insight:
        return c.insightSentence.isEmpty
            ? const CoachReply('coach.reply.insightNone')
            : CoachReply('coach.reply.insight', {'finding': c.insightSentence});

      case CoachIntent.motivate:
        // Personal beats generic: praise a live logging streak when there is one.
        if (c.loggingStreak >= 3) {
          return CoachReply(
              'coach.reply.streakPraise', {'n': c.loggingStreak});
        }
        return CoachReply('coach.reply.motivate.${c.seed % 5}');

      case CoachIntent.unknown:
        return const CoachReply('coach.reply.unknown');
    }
  }
}

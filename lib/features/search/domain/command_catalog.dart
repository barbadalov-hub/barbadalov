/// A palette entry: either a quick action to run or a place to navigate to.
enum CommandKind { action, navigate }

class Command {
  final String id;
  final String emoji;
  final String titleKey;

  /// Extra match terms (all lowercase, mixed languages) so search finds an entry
  /// even when the query doesn't match its title.
  final List<String> keywords;
  final CommandKind kind;

  const Command(
    this.id,
    this.emoji,
    this.titleKey,
    this.keywords, {
    this.kind = CommandKind.navigate,
  });
}

/// The full command catalog. Quick actions first, then every destination.
const kCommands = <Command>[
  // Quick actions.
  Command('act_water', '💧', 'search.actWater',
      ['вода', 'water', 'drink', 'попить', 'пити', 'стакан'],
      kind: CommandKind.action),
  Command('act_expense', '💸', 'search.actExpense',
      ['расход', 'потрат', 'spend', 'expense', 'трат', 'покупка', 'витрата'],
      kind: CommandKind.action),
  Command('act_mood', '📔', 'search.actMood',
      ['настроен', 'mood', 'дневник', 'настрій', 'чувств'],
      kind: CommandKind.action),

  // Primary tabs.
  Command('nav_today', '📅', 'nav.today', ['today', 'сегодня', 'сьогодні', 'дом']),
  Command('nav_money', '💰', 'nav.money',
      ['money', 'деньги', 'бюджет', 'кошелек', 'операц', 'гроші', 'дохід']),
  Command('nav_health', '❤️', 'nav.health',
      ['health', 'здоровье', 'шаги', 'вода', 'сон', 'steps', 'sleep', 'здоров']),
  Command('nav_goals', '🎯', 'nav.goals', ['goals', 'цели', 'мечта', 'saving', 'ціл']),
  Command('nav_more', '…', 'nav.more', ['more', 'ещё', 'меню', 'настройки', 'ще']),

  // Modules & tools.
  Command('food', '🥗', 'more.food', ['food', 'продукты', 'кладовая', 'pantry', 'shopping', 'їжа']),
  Command('diet', '🥦', 'diet.title', ['diet', 'калории', 'питание', 'nutrition', 'дієта']),
  Command('mind', '🧠', 'mind.title', ['mind', 'привычки', 'задачи', 'книги', 'habits', 'tasks', 'звички']),
  Command('mood', '📔', 'mood.title', ['mood', 'настроение', 'дневник']),
  Command('workouts', '🏋️', 'search.workouts', ['workout', 'тренировки', 'упражнения', 'gym', 'спорт', 'вправи']),
  Command('ai', '🤖', 'ai.title', ['ai', 'советы', 'insights']),
  Command('coach', '💬', 'coach.title', ['coach', 'коуч', 'чат', 'ассистент', 'помощник']),
  Command('insights', '🔮', 'insight.title', ['insights', 'инсайты', 'закономерности', 'patterns', 'зв’язки']),
  Command('achievements', '🏅', 'ach.title', ['achievements', 'достижения', 'бейджи', 'награды', 'badges', 'досягнення']),
  Command('wrapped', '✨', 'wrapped.title', ['wrapped', 'итоги', 'год', 'year', 'підсумки']),
  Command('lifeweeks', '⏳', 'weeks.title', ['weeks', 'жизнь', 'недели', 'life', 'тижні']),
  Command('history', '📜', 'hist.title', ['history', 'история', 'timeline', 'архив', 'історія']),
  Command('reminders', '⏰', 'reminder.title', ['reminders', 'напоминания', 'нагадування', 'alarm']),
  Command('report', '📊', 'report.title', ['report', 'отчет', 'звіт', 'weekly']),
  Command('notifications', '🔔', 'notif.title', ['notifications', 'уведомления', 'сповіщення']),
  Command('profile', '👤', 'profile.title', ['profile', 'профиль', 'тело', 'вес', 'профіль']),
  Command('appearance', '🎨', 'theme.title', ['theme', 'тема', 'оформление', 'цвет', 'dark', 'светлая', 'колір']),
  Command('backup', '💾', 'backup.title', ['backup', 'резерв', 'экспорт', 'export', 'копия']),
  Command('security', '🔒', 'sec.title', ['security', 'пин', 'pin', 'защита', 'блокировка', 'захист']),
];

/// Ranks how well [query] matches a command with the given localized [title] and
/// [keywords]. Returns 0 for no match; higher is a better match. Pure.
int commandScore(String query, String title, List<String> keywords) {
  final q = query.toLowerCase().trim();
  final t = title.toLowerCase();
  if (q.isEmpty) return 1; // no query → everything is shown at a base rank
  if (t == q) return 100;
  if (t.startsWith(q)) return 80;
  if (t.contains(q)) return 60;
  for (final k in keywords) {
    if (k.startsWith(q)) return 45;
    if (k.contains(q)) return 40;
  }
  // Multi-word query: every token appears somewhere across title + keywords.
  final tokens = q.split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
  final hay = [t, ...keywords].join(' ');
  if (tokens.isNotEmpty && tokens.every(hay.contains)) return 20;
  return 0;
}

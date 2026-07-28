/// Minimal localization for the UI chrome (buttons, labels), keyed by a dotted
/// id with ru/en/uk variants — mirroring the LifeOS i18n table. Narrative lines
/// stay in the script for now and will move onto keys the same way.
class L10n {
  const L10n(this.lang);

  final String lang;

  static const List<String> languages = <String>['ru', 'en', 'uk'];

  static String next(String current) {
    final int i = languages.indexOf(current);
    return languages[(i + 1) % languages.length];
  }

  String t(String key) {
    final Map<String, String>? row = _table[key];
    if (row == null) {
      return key;
    }
    return row[lang] ?? row['ru'] ?? key;
  }

  String tp(String key, Map<String, String> params) {
    String out = t(key);
    params.forEach((String k, String v) {
      out = out.replaceAll('{$k}', v);
    });
    return out;
  }

  static const Map<String, Map<String, String>> _table =
      <String, Map<String, String>>{
    'safe.on': <String, String>{
      'ru': 'щадящий: вкл',
      'en': 'safe mode: on',
      'uk': 'щадний: увімк',
    },
    'safe.off': <String, String>{
      'ru': 'щадящий: выкл',
      'en': 'safe mode: off',
      'uk': 'щадний: вимк',
    },
    'wake': <String, String>{
      'ru': 'Проснуться в 03:14  ↻',
      'en': 'Wake at 03:14  ↻',
      'uk': 'Прокинутися о 03:14  ↻',
    },
    'continue': <String, String>{
      'ru': 'Продолжить  ›',
      'en': 'Continue  ›',
      'uk': 'Продовжити  ›',
    },
    'assemble': <String, String>{
      'ru': 'Сложить всё вместе  ›',
      'en': 'Piece it together  ›',
      'uk': 'Скласти все разом  ›',
    },
    'tap': <String, String>{
      'ru': 'нажми, чтобы продолжить ›',
      'en': 'tap to continue ›',
      'uk': 'торкнись, щоб продовжити ›',
    },
    'memory': <String, String>{
      'ru': 'ПАМЯТЬ',
      'en': 'MEMORY',
      'uk': "ПАМ'ЯТЬ",
    },
    'collected': <String, String>{
      'ru': 'собрано {n}/{t}',
      'en': 'collected {n}/{t}',
      'uk': 'зібрано {n}/{t}',
    },
    'memory.hint': <String, String>{
      'ru': 'Вспоминать — долго. Известное всплывает мгновенно.',
      'en': 'Remembering is slow. What you know surfaces instantly.',
      'uk': 'Згадувати — довго. Відоме зринає миттєво.',
    },
    'instant': <String, String>{
      'ru': 'мгновенно ✓',
      'en': 'instant ✓',
      'uk': 'миттєво ✓',
    },
    'cost': <String, String>{
      'ru': '{clock} · −{cost}с',
      'en': '{clock} · −{cost}s',
      'uk': '{clock} · −{cost}с',
    },
    'loop': <String, String>{
      'ru': 'круг {n}',
      'en': 'loop {n}',
      'uk': 'коло {n}',
    },
  };
}

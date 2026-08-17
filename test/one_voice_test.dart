import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';

/// Formal-address markers. The app talks to one person it knows: "начни",
/// "отметь", "сегодня ты никому ничего не должен". A single "Загляните" or
/// "ваши цели" makes it sound like two different products stitched together,
/// and that is exactly how it read before this was swept.
const _formal = [
  'Ваш ', 'Ваша ', 'Ваши ', 'Ваше ', 'ваш ', 'ваша ', 'ваши ', 'ваше ',
  'вашу ', 'вашей ', 'вашего ', 'ваших ', 'вашим ', 'вашими ', 'вашем ',
  'У вас', 'вам ', 'вас ',
  'Нажмите', 'Введите', 'Выберите', 'Укажите', 'Заполните', 'Вставьте',
  'Проверьте', 'Начните', 'Отметьте', 'Попробуйте', 'Загляните', 'Держите',
  'Заботьтесь', 'Настройте', 'Запишите', 'Посмотрите',
];

/// Recipe and exercise steps are the one genre where Russian conventionally
/// uses the impersonal form, and rewriting them would read worse, not better.
bool _isInstruction(String key) => key.startsWith('recipe.');

void main() {
  test('the Russian copy speaks to one person, informally', () {
    final offenders = <String>[];

    AppLocalizations.values.forEach((key, byLang) {
      if (_isInstruction(key)) return;
      final ru = byLang['ru'];
      if (ru == null) return;
      for (final marker in _formal) {
        if (ru.contains(marker)) {
          offenders.add('$key: "$marker" in "$ru"');
          break;
        }
      }
    });

    expect(offenders, isEmpty,
        reason: 'formal address crept back in:\n${offenders.join('\n')}');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:missed_call/i18n/l10n.dart';

void main() {
  group('L10n', () {
    test('resolves the same key across ru / en / uk', () {
      expect(const L10n('ru').t('continue'), 'Продолжить  ›');
      expect(const L10n('en').t('continue'), 'Continue  ›');
      expect(const L10n('uk').t('continue'), 'Продовжити  ›');
    });

    test('interpolates params', () {
      expect(
        const L10n('en').tp('collected', <String, String>{'n': '3', 't': '7'}),
        'collected 3/7',
      );
    });

    test('falls back to ru for an unknown language, key for an unknown key', () {
      expect(const L10n('de').t('memory'), 'ПАМЯТЬ');
      expect(const L10n('en').t('no.such.key'), 'no.such.key');
    });

    test('next() cycles ru -> en -> uk -> ru', () {
      expect(L10n.next('ru'), 'en');
      expect(L10n.next('en'), 'uk');
      expect(L10n.next('uk'), 'ru');
    });
  });
}

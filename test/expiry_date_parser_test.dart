import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/food/domain/expiry_date_parser.dart';

void main() {
  const parser = ExpiryDateParser();
  final now = DateTime(2026, 1, 1);

  DateTime? p(String s) => parser.parse(s, now: now);

  test('English "best before" with dotted day-first date', () {
    expect(p('Best before 12.05.2026'), DateTime(2026, 5, 12));
  });

  test('slash day-first with 2-digit year', () {
    expect(p('EXP 12/05/26'), DateTime(2026, 5, 12));
  });

  test('ISO date', () {
    expect(p('use by 2026-05-12'), DateTime(2026, 5, 12));
  });

  test('day comes first when > 12 (unambiguous)', () {
    expect(p('25.11.2026'), DateTime(2026, 11, 25));
  });

  test('Russian "годен до" month+year → end of month', () {
    expect(p('годен до 05.2026'), DateTime(2026, 5, 31));
  });

  test('Ukrainian "придатний до" full date', () {
    expect(p('придатний до 31.12.2026'), DateTime(2026, 12, 31));
  });

  test('spelled-out English month', () {
    expect(p('USE BY 12 MAY 2026'), DateTime(2026, 5, 12));
  });

  test('spelled-out Russian month', () {
    expect(p('срок годности 07 авг 2026'), DateTime(2026, 8, 7));
  });

  test('month name + year → end of month', () {
    expect(p('best before end may 2026'), DateTime(2026, 5, 31));
  });

  test('prefers expiry date over a nearby production date', () {
    final r = p('Изготовлено 01.01.2026 Годен до 01.03.2026');
    expect(r, DateTime(2026, 3, 1));
  });

  test('ignores a production-labelled date when it is the only labelled one', () {
    // No expiry label; production date should be de-prioritised, leaving the
    // later bare date as the pick.
    final r = p('MFG 01.01.2026  15.06.2026');
    expect(r, DateTime(2026, 6, 15));
  });

  test('picks the latest plausible date when unlabelled', () {
    expect(p('10.02.2026 05.09.2026'), DateTime(2026, 9, 5));
  });

  test('rejects impossible dates', () {
    expect(p('best before 31.02.2026'), isNull);
    expect(p('40.13.2026'), isNull);
  });

  test('rejects implausibly distant / past years', () {
    expect(p('01.01.1990'), isNull); // too far in the past
    expect(p('random text with no date'), isNull);
  });

  test('does not mistake an ISO date for a day-first fragment', () {
    // "2026-05-12" must not yield 2012-05-26 from an inner "26-05-12".
    expect(p('2026-05-12'), DateTime(2026, 5, 12));
  });

  test('full dotted date is not shortened to its month/year', () {
    // "12.05.2026" must be the 12th, not end-of-May.
    expect(p('12.05.2026'), DateTime(2026, 5, 12));
  });
}

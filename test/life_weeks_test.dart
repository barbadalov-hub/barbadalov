import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/lifeweeks/domain/life_weeks.dart';

void main() {
  test('a 30-year-old has lived a third of a 90-year life', () {
    const l = LifeWeeks(ageYears: 30);
    expect(l.totalWeeks, 90 * 52);
    expect(l.weeksLived, (30 * 52.1429).round());
    expect(l.percentLived, 33);
    expect(l.yearsLeft, 60);
    expect(l.weeksLeft, l.totalWeeks - l.weeksLived);
  });

  test('clamps at the ends', () {
    expect(const LifeWeeks(ageYears: 0).weeksLived, 0);
    expect(const LifeWeeks(ageYears: 0).percentLived, 0);
    const old = LifeWeeks(ageYears: 120);
    expect(old.weeksLived, old.totalWeeks);
    expect(old.weeksLeft, 0);
    expect(old.yearsLeft, 0);
  });
}

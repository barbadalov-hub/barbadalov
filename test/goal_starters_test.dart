import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/goals/domain/goal_starters.dart';

void main() {
  test('the cushion is three months of real spending, rounded up', () {
    // 1 234.00 a month -> 3 702.00 -> a round 3 800.
    final s = GoalStarters.forUser(monthlyExpensesMinor: 123400).first;
    expect(s.titleKey, 'starter.cushion');
    expect(s.targetMinor, 380000);
    expect(s.personal, isTrue);
  });

  test('with nothing logged it falls back and does not claim to be personal',
      () {
    // A round default dressed up as "three months of your spending" would be a
    // lie, and the card only shows that line when the figure earned it.
    final s = GoalStarters.forUser(monthlyExpensesMinor: 0).first;
    expect(s.personal, isFalse);
    expect(s.targetMinor, greaterThan(0));
  });

  test('every starter has a target worth aiming at', () {
    for (final s in GoalStarters.forUser(monthlyExpensesMinor: 50000)) {
      expect(s.targetMinor, greaterThan(0), reason: '${s.titleKey} has no target');
      expect(s.emoji, isNotEmpty);
    }
  });

  test('only the cushion claims to be personal', () {
    final personal = GoalStarters.forUser(monthlyExpensesMinor: 99999)
        .where((s) => s.personal)
        .toList();
    expect(personal.length, 1);
    expect(personal.single.titleKey, 'starter.cushion');
  });

  test('a tiny month still rounds to a whole hundred, never to zero', () {
    final s = GoalStarters.forUser(monthlyExpensesMinor: 100).first;
    expect(s.targetMinor % 10000, 0);
    expect(s.targetMinor, greaterThan(0));
  });
}

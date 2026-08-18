import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/money/domain/cash_position.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/recurring_rule.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/shared/models/money.dart';

const calc = CashPositionCalculator();

Transaction _t(DateTime date, int major, {bool income = false}) => Transaction(
      id: 'id-${date.microsecondsSinceEpoch}-$major',
      amount: Money.fromMajor(major),
      type: income ? TransactionType.income : TransactionType.expense,
      categoryId: DefaultCategories.other.id,
      date: date,
    );

RecurringRule _rule(
  String label,
  int major,
  int day, {
  bool income = false,
  String lastRun = '',
}) =>
    RecurringRule(
      id: 'r-$label',
      label: label,
      type: income ? TransactionType.income : TransactionType.expense,
      amountMinor: major * 100,
      categoryId: DefaultCategories.other.id,
      dayOfMonth: day,
      lastRun: lastRun,
    );

void main() {
  group('what the app knows it does not know', () {
    test('without a stated balance it does not claim one', () {
      // The old month arithmetic reported someone who installed the app after
      // payday as having nothing. Saying "I do not know yet" is the only
      // honest answer before the user has told it.
      final p = calc.build(
        transactions: [_t(DateTime(2026, 8, 17), 30)],
        now: DateTime(2026, 8, 18),
      );
      expect(p.anchored, isFalse);
      expect(p.verdictKey, 'cash.unknown');
    });
  });

  group('the balance itself', () {
    test('is the stated amount plus everything recorded since', () {
      final anchor = BalanceAnchor(
        amount: Money.fromMajor(1000),
        on: DateTime(2026, 8, 10, 12),
      );
      final p = calc.build(
        anchor: anchor,
        transactions: [
          _t(DateTime(2026, 8, 11), 200),
          _t(DateTime(2026, 8, 12), 300, income: true),
        ],
        now: DateTime(2026, 8, 18),
      );
      expect(p.onHand, Money.fromMajor(1100));
    });

    test('does not count movements the stated amount already includes', () {
      // "I have 1 000 right now" is a statement about the past as a whole.
      // Re-applying yesterday's coffee on top of it would make every
      // reconciliation leave the figure further from the truth.
      final p = calc.build(
        anchor: BalanceAnchor(
          amount: Money.fromMajor(1000),
          on: DateTime(2026, 8, 18, 12),
        ),
        transactions: [
          _t(DateTime(2026, 8, 17), 50),
          _t(DateTime(2026, 8, 18, 9), 30),
        ],
        now: DateTime(2026, 8, 18, 12),
      );
      expect(p.onHand, Money.fromMajor(1000));
    });

    test('survives the turn of the month', () {
      // The bug this whole calculation exists to kill: on the 1st the old
      // model saw no income yet and reported nothing to spend, though the
      // money from the 25th was still sitting there.
      final p = calc.build(
        anchor: BalanceAnchor(
          amount: Money.fromMajor(800),
          on: DateTime(2026, 7, 25),
        ),
        transactions: [_t(DateTime(2026, 7, 28), 100)],
        now: DateTime(2026, 8, 1),
      );
      expect(p.onHand, Money.fromMajor(700));
      expect(p.free.isPositive, isTrue);
    });
  });

  group('money already promised', () {
    test('bills due before the next income are not free to spend', () {
      // 1 000 in hand with rent of 800 due on Friday is not 1 000 to spend.
      final p = calc.build(
        anchor: BalanceAnchor(
          amount: Money.fromMajor(1000),
          on: DateTime(2026, 8, 1),
        ),
        transactions: const [],
        rules: [_rule('rent', 800, 20), _rule('salary', 2000, 5, income: true)],
        now: DateTime(2026, 8, 18),
      );
      expect(p.committed, Money.fromMajor(800));
      expect(p.free, Money.fromMajor(200));
    });

    test('a bill that already fired this month is not charged twice', () {
      final p = calc.build(
        anchor: BalanceAnchor(
          amount: Money.fromMajor(1000),
          on: DateTime(2026, 8, 1),
        ),
        transactions: const [],
        rules: [_rule('rent', 800, 5, lastRun: '2026-08')],
        now: DateTime(2026, 8, 18),
      );
      expect(p.committed.isZero, isTrue);
    });

    test('income that was due and never arrived is not counted on', () {
      // Assuming it lands today would close the window at once and hand the
      // whole balance over as a single day's allowance. Money that has not
      // shown up is money to not spend against.
      final p = calc.build(
        anchor: BalanceAnchor(
          amount: Money.fromMajor(800),
          on: DateTime(2026, 8, 18),
        ),
        transactions: const [],
        rules: [_rule('salary', 2000, 5, income: true)],
        now: DateTime(2026, 8, 18),
      );
      expect(p.nextIncomeOn, DateTime(2026, 9, 5),
          reason: 'a missed payday is not today');
      expect(p.daysCovered, 18);
    });

    test('a bill past its day but not yet charged counts as due now', () {
      // It is about to be materialised. Treating it as a month away would
      // flatter the balance at exactly the wrong moment.
      final p = calc.build(
        anchor: BalanceAnchor(
          amount: Money.fromMajor(1000),
          on: DateTime(2026, 8, 1),
        ),
        transactions: const [],
        rules: [_rule('rent', 800, 5)],
        now: DateTime(2026, 8, 18),
      );
      expect(p.committed, Money.fromMajor(800));
    });
  });

  group('how long the money has to last', () {
    test('counts days to the next income, not days left in the month', () {
      // Paid on the 5th, today is the 28th: the money must cover eight days,
      // not the four the calendar suggests.
      final p = calc.build(
        anchor: BalanceAnchor(
          amount: Money.fromMajor(800),
          on: DateTime(2026, 8, 28),
        ),
        transactions: const [],
        rules: [_rule('salary', 2000, 5, income: true, lastRun: '2026-08')],
        now: DateTime(2026, 8, 28),
      );
      expect(p.nextIncomeOn, DateTime(2026, 9, 5));
      expect(p.daysCovered, 8);
      expect(p.perDay, Money.fromMajor(100));
    });

    test('falls back to the rest of the month when no income is scheduled', () {
      final p = calc.build(
        anchor: BalanceAnchor(
          amount: Money.fromMajor(1400),
          on: DateTime(2026, 8, 18),
        ),
        transactions: const [],
        now: DateTime(2026, 8, 18),
      );
      expect(p.nextIncomeOn, isNull);
      expect(p.daysCovered, 14,
          reason: 'the 18th through the 31st inclusive is fourteen days');
    });
  });

  group('being short', () {
    test('says so instead of flooring the number at zero', () {
      // Clamping this to zero hides the single most important fact a person
      // can be told about their money.
      final p = calc.build(
        anchor: BalanceAnchor(
          amount: Money.fromMajor(500),
          on: DateTime(2026, 8, 1),
        ),
        transactions: const [],
        rules: [_rule('rent', 800, 20)],
        now: DateTime(2026, 8, 18),
      );
      expect(p.isShort, isTrue);
      expect(p.free, Money.fromMajor(-300));
      expect(p.shortfall, Money.fromMajor(300));
      expect(p.verdictKey, 'cash.short');
    });

    test('offers no daily allowance out of money that is not there', () {
      final p = calc.build(
        anchor: BalanceAnchor(
          amount: Money.fromMajor(500),
          on: DateTime(2026, 8, 1),
        ),
        transactions: const [],
        rules: [_rule('rent', 800, 20)],
        now: DateTime(2026, 8, 18),
      );
      expect(p.perDay.isZero, isTrue,
          reason: 'nothing is safe to spend per day when nothing is free');
    });

    test('an overdrawn account reads as overdrawn', () {
      final p = calc.build(
        anchor: BalanceAnchor(
          amount: Money.fromMajor(100),
          on: DateTime(2026, 8, 1),
        ),
        transactions: [_t(DateTime(2026, 8, 5), 250)],
        now: DateTime(2026, 8, 18),
      );
      expect(p.onHand, Money.fromMajor(-150));
      expect(p.isShort, isTrue);
    });
  });

  test('savings are carved out before anything is called free', () {
    final p = calc.build(
      anchor: BalanceAnchor(
        amount: Money.fromMajor(1000),
        on: DateTime(2026, 8, 18),
      ),
      transactions: const [],
      reserve: Money.fromMajor(150),
      now: DateTime(2026, 8, 18),
    );
    expect(p.free, Money.fromMajor(850));
    expect(p.reserve, Money.fromMajor(150));
  });

  test('a stated balance with nothing promised is simply free', () {
    final p = calc.build(
      anchor: BalanceAnchor(
        amount: Money.fromMajor(600),
        on: DateTime(2026, 8, 18),
      ),
      transactions: const [],
      now: DateTime(2026, 8, 18),
    );
    expect(p.verdictKey, 'cash.free');
  });

  test('an anchor round-trips through storage', () {
    final a = BalanceAnchor(
      amount: Money.fromMajor(1234.56),
      on: DateTime(2026, 8, 18, 14, 30),
    );
    final back = BalanceAnchor.fromJson(a.toJson())!;
    expect(back.amount, a.amount);
    expect(back.on, a.on);
    expect(BalanceAnchor.fromJson(null), isNull);
    expect(BalanceAnchor.fromJson(const {'on': 'nonsense'}), isNull);
  });
}

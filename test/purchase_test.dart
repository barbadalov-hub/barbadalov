import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/money/domain/entities/purchase.dart';
import 'package:lifeos/shared/models/money.dart';

Purchase _p({
  String id = 'p',
  DateTime? bought,
  DateTime? until,
  CoverKind kind = CoverKind.warranty,
}) =>
    Purchase(
      id: id,
      title: 'Headphones',
      price: Money.fromMajor(120),
      boughtAt: bought ?? DateTime(2026, 1, 10),
      until: until,
      kind: kind,
    );

void main() {
  group('how much cover is left', () {
    final now = DateTime(2026, 6, 15, 14, 30);

    test('counts whole days, ignoring the time of day', () {
      // "Expires today" must be 0, not a fraction that rounds either way
      // depending on when the user opens the app.
      expect(_p(until: DateTime(2026, 6, 15)).daysLeft(now), 0);
      expect(_p(until: DateTime(2026, 6, 16)).daysLeft(now), 1);
      expect(_p(until: DateTime(2026, 6, 14)).daysLeft(now), -1);
    });

    test('an unknown date is not the same as no cover', () {
      final unknown = _p();
      expect(unknown.daysLeft(now), isNull);
      expect(unknown.state(now), CoverState.none);
    });

    test('the last month is the part worth acting on', () {
      expect(_p(until: DateTime(2026, 7, 20)).state(now), CoverState.covered);
      expect(_p(until: DateTime(2026, 7, 10)).state(now), CoverState.endingSoon);
      expect(_p(until: DateTime(2026, 6, 15)).state(now), CoverState.endingSoon);
      expect(_p(until: DateTime(2026, 6, 14)).state(now), CoverState.ended);
    });
  });

  group('a warranty in months becomes a date', () {
    test('one year on', () {
      expect(Purchase.addMonths(DateTime(2026, 3, 14), 12),
          DateTime(2027, 3, 14));
    });

    test('a purchase on the 31st does not slide into the next month', () {
      // 31 January + 1 month is 28 February, not 3 March.
      expect(Purchase.addMonths(DateTime(2026, 1, 31), 1),
          DateTime(2026, 2, 28));
      expect(Purchase.addMonths(DateTime(2024, 1, 31), 1),
          DateTime(2024, 2, 29), reason: 'leap year');
    });

    test('crossing a year boundary', () {
      expect(Purchase.addMonths(DateTime(2026, 11, 5), 6),
          DateTime(2027, 5, 5));
    });
  });

  group('what the list puts first', () {
    final now = DateTime(2026, 6, 15);

    test('cover about to lapse leads, expired sinks', () {
      final ordered = sortByUrgency([
        _p(id: 'expired', until: DateTime(2026, 1, 1)),
        _p(id: 'unknown'),
        _p(id: 'safe', until: DateTime(2027, 1, 1)),
        _p(id: 'soon', until: DateTime(2026, 6, 20)),
      ], now);

      expect(ordered.map((p) => p.id).toList(),
          ['soon', 'safe', 'unknown', 'expired']);
    });

    test('within a group the nearest date leads', () {
      final ordered = sortByUrgency([
        _p(id: 'later', until: DateTime(2027, 6, 1)),
        _p(id: 'sooner', until: DateTime(2026, 12, 1)),
      ], now);
      expect(ordered.first.id, 'sooner');
    });
  });

  test('a purchase round-trips through storage, receipt and all', () {
    final p = Purchase(
      id: 'x',
      title: 'Наушники',
      shop: 'DNS',
      price: Money.fromMajor(7990),
      boughtAt: DateTime(2026, 2, 3),
      until: DateTime(2027, 2, 3),
      kind: CoverKind.warranty,
      receiptDocId: 'doc-1',
      note: 'коробка на антресоли',
    );
    expect(Purchase.fromJson(p.toJson()), p);
  });

  test('a record saved without the newer fields still loads', () {
    final old = Purchase.fromJson(const {
      'id': 'y',
      'title': 'Milk',
      'priceMinor': 9900,
      'currency': 'USD',
      'boughtAt': '2026-05-01T00:00:00.000',
    });
    expect(old.until, isNull);
    expect(old.kind, CoverKind.warranty);
    expect(old.hasReceipt, isFalse);
  });
}

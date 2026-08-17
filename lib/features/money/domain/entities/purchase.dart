import 'package:equatable/equatable.dart';
import 'package:lifeos/shared/models/money.dart';

/// What the date on a kept purchase means.
enum CoverKind {
  /// A guarantee you can act on: bring the receipt back and have it replaced.
  warranty,

  /// A shelf life: after this the thing is no longer good, and nobody will
  /// take it back.
  expiry,
}

/// Where a kept purchase stands right now.
enum CoverState { covered, endingSoon, ended, none }

/// Something bought and worth remembering: the headphones, the receipt, and
/// the date until which the shop still owes you something.
///
/// The point is a moment eleven months from now, when the thing breaks and the
/// paper receipt is long gone. Everything here exists to answer one question
/// then: *am I still covered, and can I prove it?*
class Purchase extends Equatable {
  final String id;
  final String title;

  /// Where it was bought — the shop that has to honour the warranty.
  final String shop;
  final Money price;
  final DateTime boughtAt;

  /// The date cover runs out. Null means it was never recorded, which is
  /// honest: an unknown warranty is not the same as no warranty.
  final DateTime? until;
  final CoverKind kind;

  /// Id of the stored receipt photo, if one was kept.
  final String? receiptDocId;
  final String note;

  const Purchase({
    required this.id,
    required this.title,
    required this.price,
    required this.boughtAt,
    this.shop = '',
    this.until,
    this.kind = CoverKind.warranty,
    this.receiptDocId,
    this.note = '',
  });

  bool get hasReceipt => receiptDocId != null;

  /// Whole days left, negative once it has run out. Counted on calendar dates
  /// so "expires today" is 0 rather than a fraction either side of it.
  int? daysLeft(DateTime now) {
    final end = until;
    if (end == null) return null;
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(end.year, end.month, end.day).difference(today).inDays;
  }

  /// The last month of cover is the part worth acting on: it is long enough to
  /// get to the shop and short enough that forgetting costs you the claim.
  static const endingSoonDays = 30;

  CoverState state(DateTime now) {
    final days = daysLeft(now);
    if (days == null) return CoverState.none;
    if (days < 0) return CoverState.ended;
    if (days <= endingSoonDays) return CoverState.endingSoon;
    return CoverState.covered;
  }

  /// A warranty given in months, turned into a date. Clamping the day keeps a
  /// purchase made on the 31st from sliding into the next month.
  static DateTime addMonths(DateTime from, int months) {
    final targetMonth = from.month + months;
    final year = from.year + (targetMonth - 1) ~/ 12;
    final month = (targetMonth - 1) % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, from.day < lastDay ? from.day : lastDay);
  }

  Purchase copyWith({
    String? title,
    String? shop,
    Money? price,
    DateTime? boughtAt,
    DateTime? until,
    CoverKind? kind,
    String? receiptDocId,
    String? note,
    bool clearUntil = false,
    bool clearReceipt = false,
  }) =>
      Purchase(
        id: id,
        title: title ?? this.title,
        shop: shop ?? this.shop,
        price: price ?? this.price,
        boughtAt: boughtAt ?? this.boughtAt,
        until: clearUntil ? null : (until ?? this.until),
        kind: kind ?? this.kind,
        receiptDocId:
            clearReceipt ? null : (receiptDocId ?? this.receiptDocId),
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'shop': shop,
        'priceMinor': price.minorUnits,
        'currency': price.currency,
        'boughtAt': boughtAt.toIso8601String(),
        'until': until?.toIso8601String(),
        'kind': kind.name,
        'receiptDocId': receiptDocId,
        'note': note,
      };

  factory Purchase.fromJson(Map<String, dynamic> j) => Purchase(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        shop: j['shop'] as String? ?? '',
        price: Money(
          (j['priceMinor'] as num?)?.toInt() ?? 0,
          currency: j['currency'] as String? ?? const Money.zero().currency,
        ),
        boughtAt: DateTime.tryParse(j['boughtAt'] as String? ?? '') ??
            DateTime.now(),
        until: j['until'] == null
            ? null
            : DateTime.tryParse(j['until'] as String),
        kind: CoverKind.values.firstWhere(
          (k) => k.name == j['kind'],
          orElse: () => CoverKind.warranty,
        ),
        receiptDocId: j['receiptDocId'] as String?,
        note: j['note'] as String? ?? '',
      );

  @override
  List<Object?> get props =>
      [id, title, shop, price, boughtAt, until, kind, receiptDocId, note];
}

/// Sorts what matters to the top: cover that is about to lapse first, then
/// everything still covered, then dates that have passed. Within a group, the
/// nearest date leads.
List<Purchase> sortByUrgency(List<Purchase> all, DateTime now) {
  int rank(Purchase p) => switch (p.state(now)) {
        CoverState.endingSoon => 0,
        CoverState.covered => 1,
        CoverState.none => 2,
        CoverState.ended => 3,
      };
  final sorted = [...all];
  sorted.sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    final da = a.daysLeft(now), db = b.daysLeft(now);
    if (da == null && db == null) return b.boughtAt.compareTo(a.boughtAt);
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  });
  return sorted;
}

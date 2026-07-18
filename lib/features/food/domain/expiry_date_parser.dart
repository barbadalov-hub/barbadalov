/// Pulls an expiry date out of the text recognized on a product photo (OCR).
/// The recognition itself is native (ML Kit); this is the pure, testable brain
/// that turns messy label text like "Best before 12.05.2026" or
/// "придатний до 05.2026" into a [DateTime]. Pure — unit-tested.
library;

/// Month names / abbreviations across the app's languages → month number.
const Map<String, int> _months = {
  // English
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  // Russian (stems, case-insensitive)
  'янв': 1, 'фев': 2, 'мар': 3, 'апр': 4, 'мая': 5, 'май': 5, 'июн': 6,
  'июл': 7, 'авг': 8, 'сен': 9, 'окт': 10, 'ноя': 11, 'дек': 12,
  // Ukrainian
  'січ': 1, 'лют': 2, 'бер': 3, 'кві': 4, 'тра': 5, 'чер': 6,
  'лип': 7, 'сер': 8, 'вер': 9, 'жов': 10, 'лис': 11, 'гру': 12,
};

/// Phrases that mark the following date as an **expiry** (preferred).
const List<String> _expiryLabels = [
  'best before', 'best by', 'use by', 'use before', 'expiry', 'expires',
  'exp', 'bbe', 'bb',
  'годен до', 'срок годности', 'употребить до', 'реализовать до',
  'придатний до', 'вжити до', 'термін придатності', 'спожити до',
];

/// Phrases that mark the following date as a **production** date (to avoid).
const List<String> _productionLabels = [
  'mfg', 'mfd', 'prod', 'packed', 'manufactured',
  'изготовлен', 'дата изготовления', 'дата производства', 'произведено',
  'виготовлено', 'дата виготовлення',
];

class _Candidate {
  final DateTime date;
  final int index; // position in the normalized text
  const _Candidate(this.date, this.index);
}

class ExpiryDateParser {
  const ExpiryDateParser();

  /// Best-guess expiry date found in [text], or null when none is plausible.
  /// [now] bounds plausibility (defaults to DateTime.now()).
  DateTime? parse(String text, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final lower = text.toLowerCase();
    final candidates = _collect(lower, ref);
    if (candidates.isEmpty) return null;

    // Drop dates sitting right after a production label — those aren't expiry.
    final prodSpans = _labelSpans(lower, _productionLabels);
    bool nearProduction(int i) =>
        prodSpans.any((s) => i >= s && i - s <= 24);

    final expirySpans = _labelSpans(lower, _expiryLabels);
    int? nearestExpiry(int i) {
      int? best;
      for (final s in expirySpans) {
        if (i >= s && i - s <= 24) {
          final d = i - s;
          if (best == null || d < best) best = d;
        }
      }
      return best;
    }

    final usable = candidates.where((c) => !nearProduction(c.index)).toList();
    final pool = usable.isEmpty ? candidates : usable;

    // Prefer a date that directly follows an expiry label.
    final labelled = pool.where((c) => nearestExpiry(c.index) != null).toList();
    if (labelled.isNotEmpty) {
      labelled.sort((a, b) => nearestExpiry(a.index)!
          .compareTo(nearestExpiry(b.index)!));
      return labelled.first.date;
    }

    // Otherwise the latest plausible date — expiry is later than production.
    pool.sort((a, b) => b.date.compareTo(a.date));
    return pool.first.date;
  }

  List<int> _labelSpans(String text, List<String> labels) {
    final out = <int>[];
    for (final label in labels) {
      var from = 0;
      while (true) {
        final i = text.indexOf(label, from);
        if (i < 0) break;
        out.add(i + label.length);
        from = i + label.length;
      }
    }
    return out;
  }

  bool _plausible(DateTime d, DateTime ref) {
    final min = DateTime(ref.year - 2);
    final max = DateTime(ref.year + 15);
    return !d.isBefore(min) && !d.isAfter(max);
  }

  DateTime? _mk(int y, int m, int d, DateTime ref) {
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    final date = DateTime(y, m, d);
    // Reject overflow (e.g. 31 Feb rolling into March).
    if (date.month != m) return null;
    return _plausible(date, ref) ? date : null;
  }

  int _year(int y) => y < 100 ? 2000 + y : y;

  /// End-of-month for "best before MM/YYYY" style dates.
  DateTime _endOfMonth(int y, int m) => DateTime(y, m + 1, 0);

  List<_Candidate> _collect(String text, DateTime ref) {
    final out = <_Candidate>[];
    final consumed = <List<int>>[]; // [start, end) spans of full dates
    bool overlaps(int s, int e) =>
        consumed.any((c) => s < c[1] && c[0] < e);
    // Record the span as a full-date attempt (so a month/year sub-pattern
    // won't re-match inside it) even when the date turned out invalid.
    void addFull(DateTime? d, RegExpMatch m) {
      consumed.add([m.start, m.end]);
      if (d != null) out.add(_Candidate(d, m.start));
    }

    // ISO: yyyy-mm-dd (day-of-month present).
    for (final m in RegExp(r'(?<!\d)(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})(?!\d)')
        .allMatches(text)) {
      addFull(_mk(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!), ref), m);
    }
    // dd-mm-yyyy / dd.mm.yy (day first — the app's locales).
    for (final m in RegExp(r'(?<!\d)(\d{1,2})[-/.](\d{1,2})[-/.](\d{2,4})(?!\d)')
        .allMatches(text)) {
      if (overlaps(m.start, m.end)) continue;
      addFull(
          _mk(_year(int.parse(m[3]!)), int.parse(m[2]!), int.parse(m[1]!), ref),
          m);
    }
    // "12 may 2026" / "12 мая 2026" / "12 трав 2026".
    for (final m in RegExp(r'(\d{1,2})\s*([a-zа-яіїєґ]{3,})\.?\s*(\d{2,4})')
        .allMatches(text)) {
      final mon = _month(m[2]!);
      if (mon != null) {
        addFull(_mk(_year(int.parse(m[3]!)), mon, int.parse(m[1]!), ref), m);
      }
    }

    // Month + year only: "mm.yyyy" → end of month (skip if inside a full date).
    for (final m
        in RegExp(r'(?<!\d)(\d{1,2})[-/.](\d{4})(?!\d)').allMatches(text)) {
      if (overlaps(m.start, m.end)) continue;
      final mm = int.parse(m[1]!), yy = int.parse(m[2]!);
      if (mm >= 1 && mm <= 12) {
        final d = _endOfMonth(yy, mm);
        if (_plausible(d, ref)) out.add(_Candidate(d, m.start));
      }
    }
    // "may 2026" / "трав 2026" → end of month.
    for (final m
        in RegExp(r'([a-zа-яіїєґ]{3,})\.?\s*(\d{4})').allMatches(text)) {
      if (overlaps(m.start, m.end)) continue;
      final mon = _month(m[1]!);
      if (mon != null) {
        final d = _endOfMonth(int.parse(m[2]!), mon);
        if (_plausible(d, ref)) out.add(_Candidate(d, m.start));
      }
    }
    return out;
  }

  int? _month(String raw) {
    final w = raw.toLowerCase();
    if (_months.containsKey(w)) return _months[w];
    // Match by 3-letter stem for longer month words.
    final stem = w.length >= 3 ? w.substring(0, 3) : w;
    return _months[stem];
  }
}

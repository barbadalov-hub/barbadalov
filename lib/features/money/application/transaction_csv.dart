import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';

/// One row parsed from an imported CSV, before it becomes a real transaction
/// (the category is resolved by the caller: name → default category, else rules).
class ParsedCsvRow {
  final DateTime date;
  final TransactionType type;
  final int amountMinor;
  final String currency;
  final String note;
  final String categoryName;

  const ParsedCsvRow({
    required this.date,
    required this.type,
    required this.amountMinor,
    required this.currency,
    required this.note,
    required this.categoryName,
  });
}

/// Parses CSV produced by [buildTransactionsCsv] (and lenient enough for simple
/// bank exports): `Date,Type,Category,Amount,Currency,Note`. Bad rows are
/// skipped rather than failing the whole import.
List<ParsedCsvRow> parseTransactionsCsv(String csv) {
  final rows = <ParsedCsvRow>[];
  for (final raw in csv.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final f = _splitCsvLine(line);
    if (f.length < 4) continue;
    if (f[0].toLowerCase() == 'date') continue; // header
    final date = DateTime.tryParse(f[0].trim());
    if (date == null) continue;
    final major = double.tryParse(f[3].trim().replaceAll(',', '.'));
    if (major == null || major <= 0) continue;
    rows.add(ParsedCsvRow(
      date: date,
      type: f[1].trim().toLowerCase() == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amountMinor: (major * 100).round(),
      currency: f.length > 4 && f[4].trim().isNotEmpty ? f[4].trim() : 'USD',
      note: f.length > 5 ? f[5].trim() : '',
      categoryName: f.length > 2 ? f[2].trim() : '',
    ));
  }
  return rows;
}

/// Maps a CSV category name back to a built-in category id (case-insensitive),
/// or null if it doesn't match one of ours.
String? categoryIdForName(String name) {
  final low = name.toLowerCase();
  for (final c in DefaultCategories.all) {
    if (c.name.toLowerCase() == low) return c.id;
  }
  return null;
}

List<String> _splitCsvLine(String line) {
  final out = <String>[];
  final sb = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        sb.write(c);
      }
    } else if (c == '"') {
      inQuotes = true;
    } else if (c == ',') {
      out.add(sb.toString());
      sb.clear();
    } else {
      sb.write(c);
    }
  }
  out.add(sb.toString());
  return out;
}

/// Builds an Excel-friendly CSV of transactions (newest first). Pure and
/// deterministic — no I/O — so it's trivially testable; callers handle the
/// clipboard/file download.
String buildTransactionsCsv(List<Transaction> transactions) {
  final rows = <String>['Date,Type,Category,Amount,Currency,Note'];
  final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
  for (final t in sorted) {
    rows.add([
      t.date.toIso8601String().split('T').first,
      t.type.name,
      _escape(t.category.name),
      t.amount.major.toStringAsFixed(2),
      t.amount.currency,
      _escape(t.note),
    ].join(','));
  }
  return rows.join('\r\n');
}

/// RFC-4180 escaping: wrap in quotes and double any embedded quotes when the
/// value contains a comma, quote or newline.
String _escape(String value) {
  if (value.contains(RegExp('[",\r\n]'))) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

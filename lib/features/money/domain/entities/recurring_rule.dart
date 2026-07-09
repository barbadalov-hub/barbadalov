import 'package:equatable/equatable.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/shared/models/money.dart';

/// A repeating income/expense (salary, rent, subscription…) that the app
/// materialises into a real transaction once per month on [dayOfMonth].
class RecurringRule extends Equatable {
  final String id;
  final String label;
  final TransactionType type;
  final int amountMinor;
  final String categoryId;
  final int dayOfMonth; // 1..28 (kept ≤28 so every month has that day)
  final bool active;
  final String lastRun; // 'YYYY-MM' of the last time it fired, or ''

  const RecurringRule({
    required this.id,
    required this.label,
    required this.type,
    required this.amountMinor,
    required this.categoryId,
    required this.dayOfMonth,
    this.active = true,
    this.lastRun = '',
  });

  Money get amount => Money(amountMinor);

  RecurringRule copyWith({bool? active, String? lastRun}) => RecurringRule(
        id: id,
        label: label,
        type: type,
        amountMinor: amountMinor,
        categoryId: categoryId,
        dayOfMonth: dayOfMonth,
        active: active ?? this.active,
        lastRun: lastRun ?? this.lastRun,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type.name,
        'amountMinor': amountMinor,
        'categoryId': categoryId,
        'dayOfMonth': dayOfMonth,
        'active': active,
        'lastRun': lastRun,
      };

  factory RecurringRule.fromJson(Map<String, dynamic> j) => RecurringRule(
        id: j['id'] as String,
        label: (j['label'] as String?) ?? '',
        type: TransactionType.values.byName(j['type'] as String? ?? 'expense'),
        amountMinor: (j['amountMinor'] as num?)?.toInt() ?? 0,
        categoryId: (j['categoryId'] as String?) ?? DefaultCategories.other.id,
        dayOfMonth: (j['dayOfMonth'] as num?)?.toInt() ?? 1,
        active: (j['active'] as bool?) ?? true,
        lastRun: (j['lastRun'] as String?) ?? '',
      );

  @override
  List<Object?> get props =>
      [id, label, type, amountMinor, categoryId, dayOfMonth, active, lastRun];
}

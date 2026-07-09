import 'package:equatable/equatable.dart';

/// A pantry/fridge item with optional expiry tracking.
class FoodItem extends Equatable {
  final String id;
  final String name;
  final String emoji;
  final int quantity;
  final DateTime? expiry;
  final DateTime addedAt;

  const FoodItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.addedAt,
    this.quantity = 1,
    this.expiry,
  });

  /// Days until expiry (negative if already expired); null when no expiry set.
  int? daysUntilExpiry(DateTime now) {
    final e = expiry;
    if (e == null) return null;
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(e.year, e.month, e.day);
    return due.difference(today).inDays;
  }

  bool isExpired(DateTime now) {
    final d = daysUntilExpiry(now);
    return d != null && d < 0;
  }

  bool isExpiringSoon(DateTime now) {
    final d = daysUntilExpiry(now);
    return d != null && d >= 0 && d <= 3;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'quantity': quantity,
        'expiry': expiry?.toIso8601String(),
        'addedAt': addedAt.toIso8601String(),
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        quantity: (json['quantity'] as int?) ?? 1,
        expiry: json['expiry'] == null
            ? null
            : DateTime.parse(json['expiry'] as String),
        addedAt: DateTime.parse(json['addedAt'] as String),
      );

  @override
  List<Object?> get props => [id, name, emoji, quantity, expiry, addedAt];
}

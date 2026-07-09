import 'package:equatable/equatable.dart';

/// One line on the shopping list.
class ShoppingItem extends Equatable {
  final String id;
  final String name;
  final bool checked;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.checked = false,
  });

  ShoppingItem toggle() => ShoppingItem(id: id, name: name, checked: !checked);

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'checked': checked};

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'] as String,
        name: json['name'] as String,
        checked: (json['checked'] as bool?) ?? false,
      );

  @override
  List<Object?> get props => [id, name, checked];
}

import 'package:equatable/equatable.dart';

/// A recipe: a name plus its ingredients. "Add to shopping list" pushes the
/// ingredients into the shopping list (spec §7).
class Recipe extends Equatable {
  final String id;
  final String name;
  final String emoji;
  final List<String> ingredients;

  const Recipe({
    required this.id,
    required this.name,
    this.emoji = '🍽️',
    this.ingredients = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'ingredients': ingredients,
      };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: (json['emoji'] as String?) ?? '🍽️',
        ingredients: ((json['ingredients'] as List<dynamic>?) ?? const [])
            .map((e) => e as String)
            .toList(),
      );

  @override
  List<Object?> get props => [id, name, emoji, ingredients];
}

import 'package:equatable/equatable.dart';

/// A book / learning item the user is reading, with page progress (spec §9).
class Book extends Equatable {
  final String id;
  final String title;
  final String author;
  final int totalPages;
  final int currentPage;

  const Book({
    required this.id,
    required this.title,
    this.author = '',
    this.totalPages = 0,
    this.currentPage = 0,
  });

  double get progress {
    if (totalPages <= 0) return 0;
    return (currentPage / totalPages).clamp(0.0, 1.0).toDouble();
  }

  bool get isFinished => totalPages > 0 && currentPage >= totalPages;

  Book withPage(int page) => Book(
        id: id,
        title: title,
        author: author,
        totalPages: totalPages,
        currentPage: totalPages > 0 ? page.clamp(0, totalPages).toInt() : page,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'totalPages': totalPages,
        'currentPage': currentPage,
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as String,
        title: json['title'] as String,
        author: (json['author'] as String?) ?? '',
        totalPages: (json['totalPages'] as int?) ?? 0,
        currentPage: (json['currentPage'] as int?) ?? 0,
      );

  @override
  List<Object?> get props => [id, title, author, totalPages, currentPage];
}

/// A curated shelf of self-development classics the user can add to their
/// reading list in one tap. Titles/authors stay in their original form; only
/// the one-line "why read it" is localized (via [whyKey]).
class BookIdea {
  final String title;
  final String author;
  final int totalPages;
  final String whyKey;

  const BookIdea({
    required this.title,
    required this.author,
    required this.totalPages,
    required this.whyKey,
  });
}

class BookRecommendations {
  const BookRecommendations._();

  static const all = <BookIdea>[
    BookIdea(
      title: 'Atomic Habits',
      author: 'James Clear',
      totalPages: 320,
      whyKey: 'rec.atomic',
    ),
    BookIdea(
      title: 'Deep Work',
      author: 'Cal Newport',
      totalPages: 296,
      whyKey: 'rec.deepWork',
    ),
    BookIdea(
      title: 'The Psychology of Money',
      author: 'Morgan Housel',
      totalPages: 256,
      whyKey: 'rec.psychMoney',
    ),
    BookIdea(
      title: 'Rich Dad Poor Dad',
      author: 'Robert Kiyosaki',
      totalPages: 336,
      whyKey: 'rec.richDad',
    ),
    BookIdea(
      title: 'Thinking, Fast and Slow',
      author: 'Daniel Kahneman',
      totalPages: 499,
      whyKey: 'rec.thinking',
    ),
    BookIdea(
      title: 'Mindset',
      author: 'Carol Dweck',
      totalPages: 320,
      whyKey: 'rec.mindset',
    ),
    BookIdea(
      title: 'The 7 Habits of Highly Effective People',
      author: 'Stephen Covey',
      totalPages: 381,
      whyKey: 'rec.sevenHabits',
    ),
    BookIdea(
      title: 'Ego Is the Enemy',
      author: 'Ryan Holiday',
      totalPages: 256,
      whyKey: 'rec.ego',
    ),
    BookIdea(
      title: "Man's Search for Meaning",
      author: 'Viktor Frankl',
      totalPages: 184,
      whyKey: 'rec.meaning',
    ),
    BookIdea(
      title: 'The Almanack of Naval Ravikant',
      author: 'Eric Jorgenson',
      totalPages: 244,
      whyKey: 'rec.naval',
    ),
  ];
}

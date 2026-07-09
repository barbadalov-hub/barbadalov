import 'package:equatable/equatable.dart';

enum InsightCategory { finance, health, food, discipline, general }

/// A single piece of AI guidance surfaced on Today and the AI screen, and
/// persisted to `ai_insights/` in Phase 3.
///
/// The engine emits **i18n keys + params**, never final prose — the UI resolves
/// them via `context.tr`/`context.trp`, so insights follow the app language
/// even though they are generated inside the Core Engine (no BuildContext).
class AiInsight extends Equatable {
  final String id;
  final InsightCategory category;
  final String emoji;
  final String titleKey;
  final String messageKey;
  final Map<String, Object> params;

  const AiInsight({
    required this.id,
    required this.category,
    required this.emoji,
    required this.titleKey,
    required this.messageKey,
    this.params = const {},
  });

  @override
  List<Object?> get props =>
      [id, category, emoji, titleKey, messageKey, params];
}

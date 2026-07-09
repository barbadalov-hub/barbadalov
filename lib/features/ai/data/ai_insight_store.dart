import 'dart:async';

import 'package:lifeos/features/ai/domain/ai_insight.dart';

/// Holds the latest set of AI insights (current-state snapshot, replaced on each
/// analysis) and streams them to the UI. Local stand-in for `ai_insights/`.
class AiInsightStore {
  List<AiInsight> _insights = const [];
  final StreamController<List<AiInsight>> _controller =
      StreamController<List<AiInsight>>.broadcast();

  List<AiInsight> get current => _insights;

  void replace(List<AiInsight> insights) {
    _insights = List.unmodifiable(insights);
    if (!_controller.isClosed) _controller.add(_insights);
  }

  Stream<List<AiInsight>> watch() async* {
    yield _insights;
    yield* _controller.stream;
  }

  Future<void> dispose() => _controller.close();
}

import 'package:lifeos/core/events/event_handler.dart';
import 'package:lifeos/core/events/life_event.dart';
import 'package:lifeos/features/ai/data/ai_insight_store.dart';
import 'package:lifeos/features/ai/domain/ai_engine.dart';
import 'package:lifeos/features/ai/domain/life_context.dart';

/// Runs the AI Engine as a reaction to the event stream — satisfying the rule
/// that AI is invoked through the Core Engine, never from the UI. On any event
/// it rebuilds the [LifeContext] from current state, re-analyses, and stores the
/// fresh insights.
class AiEventHandler implements EventHandler {
  final AiEngine _engine;
  final AiInsightStore _store;
  final LifeContext Function() _buildContext;

  AiEventHandler({
    required AiEngine engine,
    required AiInsightStore store,
    required LifeContext Function() buildContext,
  })  : _engine = engine,
        _store = store,
        _buildContext = buildContext;

  @override
  String get name => 'AiEngine';

  @override
  bool canHandle(LifeEvent event) => true;

  @override
  Future<void> handle(LifeEvent event) async => analyzeNow();

  /// Also called once at bootstrap so Today has insights before the first event.
  void analyzeNow() => _store.replace(_engine.analyze(_buildContext()));
}

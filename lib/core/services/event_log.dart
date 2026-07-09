import 'dart:async';

import 'package:lifeos/core/events/event_handler.dart';
import 'package:lifeos/core/events/life_event.dart';

/// The append-only event log — the local stand-in for the Firebase `events/`
/// collection. Every [LifeEvent] the engine sees is written here verbatim,
/// giving the system a complete, replayable history of the user's life.
class EventLog {
  final List<Map<String, dynamic>> _entries = [];
  final StreamController<List<Map<String, dynamic>>> _controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  List<Map<String, dynamic>> get entries => List.unmodifiable(_entries);
  int get length => _entries.length;

  void append(LifeEvent event) {
    _entries.add(event.toEnvelope());
    if (!_controller.isClosed) _controller.add(entries);
  }

  Stream<List<Map<String, dynamic>>> watch() async* {
    yield entries;
    yield* _controller.stream;
  }

  Future<void> dispose() => _controller.close();
}

/// The universal handler that realises the rule "everything is an event, and
/// every event is recorded". Registered first with the [LifeCoreEngine].
class EventLogHandler implements EventHandler {
  final EventLog _log;
  const EventLogHandler(this._log);

  @override
  String get name => 'EventLog';

  @override
  bool canHandle(LifeEvent event) => true;

  @override
  Future<void> handle(LifeEvent event) async => _log.append(event);
}

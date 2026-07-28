import 'package:flutter/foundation.dart';

import 'models.dart';

/// Drives the visual novel: keeps the current node, advances linear beats and
/// resolves choices. Deliberately a plain [ChangeNotifier] — no Riverpod, no
/// third-party state package — so the prototype stays dependency-free.
class VnController extends ChangeNotifier {
  VnController({
    required Map<String, VnNode> script,
    required String startId,
  })  : _script = script,
        _startId = startId,
        _currentId = startId;

  final Map<String, VnNode> _script;
  final String _startId;
  String _currentId;

  /// Flags the player has tripped (viewed CGs, remembered fragments, deaths).
  /// These persist across a death loop — the "hybrid" knowledge carry-over.
  final Set<String> flags = <String>{};

  /// How many times a death has thrown the night back to the start.
  int loopCount = 0;

  VnNode get current => _script[_currentId]!;

  /// Move to the next linear node. No-op when the node offers choices.
  void advance() {
    if (current.choices.isNotEmpty) {
      return;
    }
    final String? nextId = current.next;
    if (nextId != null && _script.containsKey(nextId)) {
      _currentId = nextId;
      notifyListeners();
    }
  }

  /// Jump to the branch a [choice] points at.
  void choose(VnChoice choice) {
    if (_script.containsKey(choice.goto)) {
      _currentId = choice.goto;
      notifyListeners();
    }
  }

  /// A horror death: the night snaps back to 03:14, but knowledge stays.
  /// Records that this death was seen (used later for hybrid carry-over).
  void loopFromDeath(String diedFrom) {
    flags.add('died:$diedFrom');
    loopCount++;
    _currentId = _startId;
    notifyListeners();
  }

  /// Full restart of the slice — clears everything (menu-style).
  void restart() {
    _currentId = _startId;
    flags.clear();
    loopCount = 0;
    notifyListeners();
  }
}

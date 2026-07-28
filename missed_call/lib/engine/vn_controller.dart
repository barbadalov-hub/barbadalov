import 'package:flutter/foundation.dart';

import 'fragments.dart';
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

  // --- Night timer: the night runs 03:14 -> 03:47 (the immovable deadline). ---
  /// Real seconds the whole night lasts. Short for the slice; the full game
  /// runs it close to real time (~33 min). See docs/design.md.
  static const double nightSeconds = 150;

  double _nightElapsed = 0;
  bool _timeUpTriggered = false;

  double get nightProgress => (_nightElapsed / nightSeconds).clamp(0.0, 1.0);
  bool get isTimeUp => _nightElapsed >= nightSeconds;

  /// In-game wall clock, 03:14 at start → 03:47 at the deadline, as "HH:MM".
  String get nightClock {
    const int startMin = 3 * 60 + 14; // 194
    const int endMin = 3 * 60 + 47; // 227
    final int total = (startMin + (endMin - startMin) * nightProgress).round();
    final String hh = (total ~/ 60).toString().padLeft(2, '0');
    final String mm = (total % 60).toString().padLeft(2, '0');
    return '$hh:$mm';
  }

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

  /// Advance the night clock by [dtSeconds] of real time (driven by the UI).
  void tickNight(double dtSeconds) {
    if (isTimeUp) {
      return;
    }
    _nightElapsed += dtSeconds;
    if (_nightElapsed > nightSeconds) {
      _nightElapsed = nightSeconds;
    }
  }

  /// The deadline hit 03:47 — route into the "Время вышло" horror death.
  void triggerTimeUp() {
    if (_timeUpTriggered || !_script.containsKey('death_time')) {
      return;
    }
    _timeUpTriggered = true;
    _currentId = 'death_time';
    notifyListeners();
  }

  void _resetNight() {
    _nightElapsed = 0;
    _timeUpTriggered = false;
  }

  // --- Memory fragments (hybrid loop): known fragments recall for free. ---
  bool isFragmentKnown(String id) => flags.contains('fragment:$id');

  int get fragmentsFound =>
      flags.where((String f) => f.startsWith('fragment:')).length;

  bool get allFragmentsFound => fragmentsFound >= kFragments.length;

  /// Leave the memory hub: collecting all seven fragments unlocks the true
  /// ending «Голосовое»; otherwise continue to the next node.
  void leaveMemoryHub() {
    if (allFragmentsFound && _script.containsKey('ending_true')) {
      _currentId = 'ending_true';
      notifyListeners();
    } else {
      advance();
    }
  }

  /// Recall a memory. The first time it costs [MemoryFragment.cost] seconds of
  /// the night; once known it is instant and free (persists across death loops).
  void recall(MemoryFragment fragment) {
    if (isFragmentKnown(fragment.id)) {
      return;
    }
    tickNight(fragment.cost.toDouble());
    flags.add('fragment:${fragment.id}');
  }

  /// A horror death: the night snaps back to 03:14, but knowledge stays.
  /// Records that this death was seen (used later for hybrid carry-over).
  void loopFromDeath(String diedFrom) {
    flags.add('died:$diedFrom');
    loopCount++;
    _currentId = _startId;
    _resetNight();
    notifyListeners();
  }

  /// Full restart of the slice — clears everything (menu-style).
  void restart() {
    _currentId = _startId;
    flags.clear();
    loopCount = 0;
    _resetNight();
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';

/// Emotional palette of a scene — the single most important art device.
/// The whole screen tint shifts with the mood of the moment.
enum Mood { night, memory, dread, dawn }

/// Who "voices" a line of the script.
enum Speaker { narration, thought, mira, you, artem }

/// Art brief for a CG (a full-screen illustration event).
///
/// Until real anime art is produced from the character/scene briefs, the UI
/// renders a mood-tinted placeholder plus [brief] so the scene still reads.
@immutable
class CgSpec {
  const CgSpec({
    required this.id,
    required this.mood,
    required this.brief,
  });

  final String id;
  final Mood mood;
  final String brief;
}

/// A single line of dialogue or narration.
@immutable
class VnLine {
  const VnLine(this.speaker, this.text);

  final Speaker speaker;
  final String text;
}

/// A branching option shown at the end of a node.
@immutable
class VnChoice {
  const VnChoice({
    required this.label,
    required this.goto,
    this.tag = '',
  });

  /// Text on the button.
  final String label;

  /// Id of the node this choice jumps to.
  final String goto;

  /// Optional hint of the choice's "lane" (e.g. расследование / действие).
  final String tag;
}

/// One beat of the story: a CG, its lines, and where it leads.
///
/// A node is *linear* when [choices] is empty — it flows to [next]. When
/// [choices] is non-empty the player picks the branch. A node with neither is
/// an ending.
@immutable
class VnNode {
  const VnNode({
    required this.id,
    required this.cg,
    this.lines = const <VnLine>[],
    this.choices = const <VnChoice>[],
    this.next,
    this.isDeath = false,
    this.isMemoryHub = false,
  });

  final String id;
  final CgSpec cg;
  final List<VnLine> lines;
  final List<VnChoice> choices;
  final String? next;

  /// A horror dead-end: playing it out loops the night back to 03:14.
  final bool isDeath;

  /// A memory screen: the player recalls fragments (each costs night time,
  /// known ones are free) before continuing to [next].
  final bool isMemoryHub;

  bool get isEnding => choices.isEmpty && next == null && !isDeath;
}

/// One of the seven memories that reconstruct the night. Recalling an unknown
/// fragment costs [cost] seconds of the night; a known one is free (the hybrid
/// loop's "instant recall").
@immutable
class MemoryFragment {
  const MemoryFragment({
    required this.id,
    required this.title,
    required this.clock,
    required this.brief,
    required this.cost,
  });

  final String id;
  final String title;

  /// The in-fiction time this memory sits at (display only).
  final String clock;
  final String brief;

  /// Seconds of the night it costs to dredge this up for the first time.
  final int cost;
}

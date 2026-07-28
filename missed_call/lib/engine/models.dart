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
  });

  final String id;
  final CgSpec cg;
  final List<VnLine> lines;
  final List<VnChoice> choices;
  final String? next;

  /// A horror dead-end: playing it out loops the night back to 03:14.
  final bool isDeath;

  bool get isEnding => choices.isEmpty && next == null && !isDeath;
}

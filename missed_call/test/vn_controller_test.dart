import 'package:flutter_test/flutter_test.dart';
import 'package:missed_call/engine/models.dart';
import 'package:missed_call/engine/script_act1.dart';
import 'package:missed_call/engine/vn_controller.dart';

void main() {
  group('Act I script', () {
    test('starts at the ring node', () {
      final VnController c =
          VnController(script: actOneScript, startId: kActOneStart);
      expect(c.current.id, 'ring');
    });

    test('every next/goto target exists in the script', () {
      for (final VnNode node in actOneScript.values) {
        final String? next = node.next;
        if (next != null) {
          expect(actOneScript.containsKey(next), isTrue,
              reason: 'missing next "$next" from "${node.id}"');
        }
        for (final VnChoice choice in node.choices) {
          expect(actOneScript.containsKey(choice.goto), isTrue,
              reason: 'missing goto "${choice.goto}" from "${node.id}"');
        }
      }
    });

    test('advance walks the linear prologue to the branching message', () {
      final VnController c =
          VnController(script: actOneScript, startId: kActOneStart);
      c.advance(); // ring -> wake
      expect(c.current.id, 'wake');
      c.advance(); // wake -> clock
      c.advance(); // clock -> message
      expect(c.current.id, 'message');
      expect(c.current.choices, isNotEmpty);
    });

    test('advance is a no-op on a node that has choices', () {
      final VnController c =
          VnController(script: actOneScript, startId: 'message');
      c.advance();
      expect(c.current.id, 'message');
    });

    test('choosing jumps to the branch and reaches the memory insert', () {
      final VnController c =
          VnController(script: actOneScript, startId: 'message');
      c.choose(c.current.choices.first); // -> branch_where
      expect(c.current.id, 'branch_where');
      c.advance(); // -> memory
      expect(c.current.id, 'memory');
      expect(c.current.cg.mood, Mood.memory);
    });

    test('restart returns to the start and clears flags', () {
      final VnController c =
          VnController(script: actOneScript, startId: kActOneStart);
      c.advance();
      c.flags.add('seen_mirror');
      c.restart();
      expect(c.current.id, kActOneStart);
      expect(c.flags, isEmpty);
    });
  });
}

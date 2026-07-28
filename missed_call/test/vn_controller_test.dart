import 'package:flutter_test/flutter_test.dart';
import 'package:missed_call/engine/fragments.dart';
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

  group('Horror dead-ends', () {
    test('a lethal choice leads to a death node', () {
      final VnController c =
          VnController(script: actOneScript, startId: 'branch_who');
      final VnChoice lethal =
          c.current.choices.firstWhere((VnChoice ch) => ch.tag == 'тупик');
      c.choose(lethal);
      expect(c.current.isDeath, isTrue);
      expect(c.current.isEnding, isFalse);
      expect(c.current.cg.mood, Mood.dread);
    });

    test('loopFromDeath returns to 03:14, keeps flags and counts the loop', () {
      final VnController c =
          VnController(script: actOneScript, startId: kActOneStart);
      c.advance(); // ring -> wake
      c.advance(); // wake -> clock
      c.advance(); // clock -> message
      c.choose(c.current.choices
          .firstWhere((VnChoice ch) => ch.goto == 'branch_call'));
      c.choose(
          c.current.choices.firstWhere((VnChoice ch) => ch.tag == 'тупик'));
      expect(c.current.id, 'death_line');

      c.flags.add('fragment:mirror');
      c.loopFromDeath(c.current.id);
      expect(c.current.id, kActOneStart);
      expect(c.loopCount, 1);
      expect(c.flags, contains('fragment:mirror')); // knowledge persists
      expect(c.flags, contains('died:death_line'));
    });

    test('every choice-death node is reachable from a lethal choice', () {
      // death_time is triggered by the night timer, not a choice.
      final Set<String> deathIds = <String>{
        for (final VnNode n in actOneScript.values)
          if (n.isDeath && n.id != 'death_time') n.id,
      };
      final Set<String> targeted = <String>{
        for (final VnNode n in actOneScript.values)
          for (final VnChoice ch in n.choices)
            if (actOneScript[ch.goto]?.isDeath ?? false) ch.goto,
      };
      expect(targeted, containsAll(deathIds));
    });
  });

  group('Night timer', () {
    test('clock reads 03:14 at start and 03:47 at the deadline', () {
      final VnController c =
          VnController(script: actOneScript, startId: kActOneStart);
      expect(c.nightClock, '03:14');
      expect(c.isTimeUp, isFalse);

      c.tickNight(VnController.nightSeconds / 2);
      expect(c.nightProgress, closeTo(0.5, 0.01));

      c.tickNight(VnController.nightSeconds); // overshoot the deadline
      expect(c.isTimeUp, isTrue);
      expect(c.nightProgress, 1.0);
      expect(c.nightClock, '03:47');
    });

    test('timeout routes to the "Время вышло" death; loop resets the night', () {
      final VnController c =
          VnController(script: actOneScript, startId: kActOneStart);
      c.tickNight(VnController.nightSeconds + 1);
      c.triggerTimeUp();
      expect(c.current.id, 'death_time');
      expect(c.current.isDeath, isTrue);

      c.loopFromDeath(c.current.id);
      expect(c.current.id, kActOneStart);
      expect(c.isTimeUp, isFalse);
      expect(c.nightProgress, 0.0);
      expect(c.nightClock, '03:14');
    });
  });

  group('Memory fragments', () {
    test('recalling an unknown fragment costs night time and marks it known', () {
      final VnController c =
          VnController(script: actOneScript, startId: kActOneStart);
      final MemoryFragment f = kFragments.first;
      expect(c.isFragmentKnown(f.id), isFalse);
      final double before = c.nightProgress;
      c.recall(f);
      expect(c.isFragmentKnown(f.id), isTrue);
      expect(c.fragmentsFound, 1);
      expect(c.nightProgress, greaterThan(before));
    });

    test('a known fragment recalls for free — even after a death loop', () {
      final VnController c =
          VnController(script: actOneScript, startId: kActOneStart);
      final MemoryFragment f = kFragments.first;
      c.recall(f); // charged
      c.loopFromDeath('death_time'); // night resets, knowledge persists
      expect(c.isFragmentKnown(f.id), isTrue);
      final double before = c.nightProgress; // 0 after reset
      c.recall(f); // instant recall — no cost
      expect(c.nightProgress, before);
      expect(c.fragmentsFound, 1);
    });
  });

  group('True ending', () {
    test('leaving the hub without all fragments continues to slice_end', () {
      final VnController c =
          VnController(script: actOneScript, startId: 'memory_hub');
      expect(c.allFragmentsFound, isFalse);
      c.leaveMemoryHub();
      expect(c.current.id, 'slice_end');
    });

    test('collecting all seven fragments unlocks «Голосовое»', () {
      final VnController c =
          VnController(script: actOneScript, startId: 'memory_hub');
      for (final MemoryFragment f in kFragments) {
        c.recall(f);
      }
      expect(c.allFragmentsFound, isTrue);
      c.leaveMemoryHub();
      expect(c.current.id, 'ending_true');
      expect(c.current.cg.mood, Mood.dawn);
      expect(c.current.choices, isNotEmpty);
    });
  });
}

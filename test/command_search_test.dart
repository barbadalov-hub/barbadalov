import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/search/domain/command_catalog.dart';

void main() {
  group('commandScore', () {
    test('empty query shows everything at a base rank', () {
      expect(commandScore('', 'Money', const []), 1);
    });

    test('ranks exact > prefix > contains > keyword', () {
      expect(commandScore('money', 'Money', const []), 100);
      expect(commandScore('mon', 'Money', const []), 80);
      expect(commandScore('one', 'Money', const []), 60);
      expect(commandScore('деньги', 'Money', const ['деньги']), 45);
      expect(commandScore('еньг', 'Money', const ['деньги']), 40);
    });

    test('no match returns 0', () {
      expect(commandScore('zzz', 'Money', const ['деньги']), 0);
    });

    test('multi-word query matches when all tokens appear', () {
      expect(commandScore('add water', 'Water', const ['add', 'drink']),
          greaterThan(0));
      expect(commandScore('add zzz', 'Water', const ['add', 'drink']), 0);
    });
  });

  group('catalog integrity', () {
    test('command ids are unique', () {
      final ids = kCommands.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('has both actions and navigation entries', () {
      expect(kCommands.any((c) => c.kind == CommandKind.action), isTrue);
      expect(kCommands.any((c) => c.kind == CommandKind.navigate), isTrue);
    });
  });
}

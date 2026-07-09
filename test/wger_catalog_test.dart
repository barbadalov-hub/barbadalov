import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/health/data/wger_catalog_service.dart';

void main() {
  group('WgerCatalogService.parsePage', () {
    final page = {
      'results': [
        {
          'id': 42,
          'category': {'name': 'Legs'},
          'muscles': [
            {'name': 'Quadriceps femoris', 'name_en': 'Quads'},
            {'name': 'Gluteus maximus', 'name_en': ''},
          ],
          'translations': [
            {'language': 2, 'name': 'Squat', 'description': '<p>Keep the <b>back</b> straight.</p>'},
            {'language': 5, 'name': 'Приседания', 'description': '<p>Спина&nbsp;прямая.</p>'},
          ],
          'images': [
            {'image': 'https://wger.de/media/a.png', 'is_main': false},
            {'image': 'https://wger.de/media/main.png', 'is_main': true},
          ],
          'videos': [
            {'video': 'https://wger.de/media/exercise-video/42/x.mp4'},
          ],
        },
        {
          // No translation in any requested language → skipped.
          'id': 43,
          'category': {'name': 'Arms'},
          'muscles': <Map<String, dynamic>>[],
          'translations': [
            {'language': 1, 'name': 'Kniebeuge', 'description': ''},
          ],
          'images': <Map<String, dynamic>>[],
          'videos': <Map<String, dynamic>>[],
        },
      ],
    };

    test('prefers Russian, falls back to English, strips HTML', () {
      final ru = WgerCatalogService.parsePage(page, [5, 2]);
      expect(ru.length, 1); // German-only entry skipped
      expect(ru.single.name, 'Приседания');
      expect(ru.single.description, 'Спина прямая.');

      final en = WgerCatalogService.parsePage(page, [2]);
      expect(en.single.name, 'Squat');
      expect(en.single.description, 'Keep the back straight.');
    });

    test('picks the main image, the video, and english muscle names', () {
      final e = WgerCatalogService.parsePage(page, [2]).single;
      expect(e.imageUrl, 'https://wger.de/media/main.png');
      expect(e.videoUrl, contains('exercise-video/42'));
      expect(e.muscles, ['Quads', 'Gluteus maximus']);
      expect(e.category, 'Legs');
    });

    test('json round-trip keeps every field', () {
      final e = WgerCatalogService.parsePage(page, [2]).single;
      final back = WgerExercise.fromJson(e.toJson());
      expect(back.name, e.name);
      expect(back.imageUrl, e.imageUrl);
      expect(back.videoUrl, e.videoUrl);
      expect(back.muscles, e.muscles);
    });
  });
}

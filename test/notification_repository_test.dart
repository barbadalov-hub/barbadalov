import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/notifications/data/notification_repository_impl.dart';
import 'package:lifeos/features/notifications/domain/entities/app_notification.dart';

AppNotification _n(String id) => AppNotification(
      id: id,
      tier: NotificationTier.optional,
      titleKey: 'k.title',
      bodyKey: 'k.body',
      params: const {},
      createdAt: DateTime(2024, 1, 1),
    );

void main() {
  test('add inserts newest-first; remove and clear work', () {
    final repo = NotificationRepositoryImpl();
    addTearDown(repo.dispose);

    repo.add(_n('a'));
    repo.add(_n('b'));
    expect(repo.all().map((n) => n.id).toList(), ['b', 'a']);

    repo.remove('b');
    expect(repo.all().map((n) => n.id).toList(), ['a']);

    repo.add(_n('c'));
    repo.clear();
    expect(repo.all(), isEmpty);
  });

  test('markAllRead marks every notification read', () {
    final repo = NotificationRepositoryImpl();
    addTearDown(repo.dispose);
    repo.add(_n('a'));
    repo.add(_n('b'));
    expect(repo.all().every((n) => n.read), isFalse);
    repo.markAllRead();
    expect(repo.all().every((n) => n.read), isTrue);
  });

  test('remove of a missing id is a no-op', () {
    final repo = NotificationRepositoryImpl();
    addTearDown(repo.dispose);
    repo.add(_n('a'));
    repo.remove('nope');
    expect(repo.all().length, 1);
  });
}

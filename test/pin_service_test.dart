import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/security/application/pin_service.dart';

void main() {
  const svc = PinService();

  test('hash is stable, non-reversible-looking, and verifies', () {
    final h = svc.hash('1234');
    expect(h, svc.hash('1234')); // deterministic
    expect(h, isNot('1234')); // not plaintext
    expect(h.length, 64); // sha-256 hex
    expect(svc.verify('1234', h), isTrue);
    expect(svc.verify('0000', h), isFalse);
  });

  test('empty stored hash never verifies', () {
    expect(svc.verify('1234', ''), isFalse);
  });
}

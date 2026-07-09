import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Hashing for the local app-lock PIN. The PIN itself is never stored — only a
/// salted SHA-256 digest, on-device. This is a convenience lock (keep casual
/// snoopers out of finance/cycle data), not full-disk encryption.
class PinService {
  const PinService();

  static const _salt = 'lifeos.pin.v1';

  String hash(String pin) =>
      sha256.convert(utf8.encode('$_salt:$pin')).toString();

  bool verify(String pin, String storedHash) =>
      storedHash.isNotEmpty && hash(pin) == storedHash;
}

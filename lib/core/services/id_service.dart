import 'package:uuid/uuid.dart';

/// Abstraction over id generation so tests can inject deterministic ids.
abstract class IdService {
  String newId();
}

class UuidIdService implements IdService {
  const UuidIdService();
  static const _uuid = Uuid();

  @override
  String newId() => _uuid.v4();
}

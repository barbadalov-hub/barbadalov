/// Low-level exceptions thrown *inside* the Data layer. They are always caught
/// at the repository boundary and mapped to a [Failure] before travelling up.
library;

class StorageException implements Exception {
  final String message;
  const StorageException(this.message);
  @override
  String toString() => 'StorageException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  @override
  String toString() => 'NetworkException: $message';
}

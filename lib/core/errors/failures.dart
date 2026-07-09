import 'package:equatable/equatable.dart';

/// Domain-level, user-safe error descriptions. Failures cross layer boundaries
/// (Data → Application → Presentation); raw [Exception]s never should.
sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Input did not satisfy a business rule (e.g. negative amount, empty title).
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Reading from or writing to a data source failed.
final class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

/// A network/backend call failed (Firebase, AI provider, ...).
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Anything we did not anticipate. Should be rare and always logged.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}

import 'package:lifeos/core/errors/failures.dart';

/// A functional result type used across the Application and Data layers so that
/// expected error paths are part of the type signature instead of thrown
/// exceptions. UseCases return `Result<T>`; the UI decides how to render each
/// branch with [fold].
sealed class Result<T> {
  const Result();

  /// Collapse both branches into a single value.
  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T value) onSuccess,
  );

  bool get isSuccess => this is Ok<T>;
  bool get isFailure => this is Err<T>;

  /// The success value, or `null` when this is a failure.
  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);

  @override
  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T value) onSuccess,
  ) =>
      onSuccess(value);
}

final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);

  @override
  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T value) onSuccess,
  ) =>
      onFailure(failure);
}

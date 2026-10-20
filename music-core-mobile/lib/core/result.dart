/// A small explicit result type used at data and domain seams.
sealed class Result<T> {
  const Result();
}

/// A successful operation.
final class ResultOk<T> extends Result<T> {
  const ResultOk(this.value);

  final T value;
}

/// An operation that failed with a user-safe, typed failure.
final class ResultError<T> extends Result<T> {
  const ResultError(this.failure);

  final AppFailure failure;
}

/// Failure categories that are meaningful outside the data layer.
abstract class AppFailure implements Exception {
  const AppFailure();
}

/// A local persistence operation failed.
final class StorageFailure extends AppFailure {
  const StorageFailure([this.message = 'Storage error']);
  final String message;
}

/// A network connection error occurred (offline, timeout, unreachable).
final class NetworkFailure extends AppFailure {
  const NetworkFailure([this.message = 'Network connection error. Please check your connection.']);
  final String message;
}

/// Authentication failed (401 invalid credentials or expired token).
final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([this.message = 'Invalid credentials or session expired.']);
  final String message;
}

/// Resource conflict (409 email already exists).
final class ConflictFailure extends AppFailure {
  const ConflictFailure([this.message = 'Resource already exists.']);
  final String message;
}

/// Server returned a 5xx error.
final class ServerFailure extends AppFailure {
  const ServerFailure([this.message = 'Server error occurred. Please try again later.']);
  final String message;
}

/// Validation or Bad Request (400).
final class ValidationFailure extends AppFailure {
  const ValidationFailure([this.message = 'Invalid request parameters.']);
  final String message;
}

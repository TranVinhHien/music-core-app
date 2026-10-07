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
  const StorageFailure();
}

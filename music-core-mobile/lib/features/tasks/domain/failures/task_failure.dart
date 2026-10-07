import '../../../../core/result.dart';

/// A task title did not satisfy the domain invariant.
final class InvalidTaskTitleFailure extends AppFailure {
  const InvalidTaskTitleFailure();
}

/// A requested task does not exist for the current account.
final class TaskNotFoundFailure extends AppFailure {
  const TaskNotFoundFailure();
}

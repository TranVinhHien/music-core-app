import '../../../../core/result.dart';
import '../failures/task_failure.dart';

/// A task title with the only invariant required by the Demo product.
final class TaskTitle {
  const TaskTitle._(this.value);

  final String value;

  /// Trims input and rejects an empty title.
  static Result<TaskTitle> create(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) return const ResultError(InvalidTaskTitleFailure());
    return ResultOk(TaskTitle._(value));
  }
}

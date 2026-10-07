import '../../../../core/result.dart';
import '../entities/task_filter.dart';
import '../entities/task_item.dart';
import '../value_objects/task_title.dart';

/// Source of truth for account-scoped tasks.
abstract interface class TaskRepository {
  Stream<List<TaskItem>> watchTasks({
    required String ownerId,
    required TaskFilter filter,
  });

  Future<Result<void>> createTask({
    required String ownerId,
    required TaskTitle title,
  });

  Future<Result<void>> renameTask({
    required String ownerId,
    required String id,
    required TaskTitle title,
  });

  Future<Result<void>> setCompleted({
    required String ownerId,
    required String id,
    required bool isCompleted,
  });

  Future<Result<void>> deleteTask({
    required String ownerId,
    required String id,
  });
}

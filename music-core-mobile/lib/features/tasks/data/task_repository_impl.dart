import 'package:uuid/uuid.dart';

import '../../../../core/result.dart';
import '../domain/entities/task_filter.dart';
import '../domain/entities/task_item.dart';
import '../domain/failures/task_failure.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/value_objects/task_title.dart';
import 'task_database.dart';
import 'task_dao.dart';

/// Drift-backed implementation of the task repository.
final class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(TaskDatabase database)
    : _dao = database.taskDao,
      _uuid = const Uuid();

  final TaskDao _dao;
  final Uuid _uuid;

  @override
  Stream<List<TaskItem>> watchTasks({
    required String ownerId,
    required TaskFilter filter,
  }) async* {
    try {
      await for (final rows in _dao.watchForOwner(ownerId, filter)) {
        yield rows.map(_toDomain).toList(growable: false);
      }
    } on Exception {
      throw const StorageFailure();
    }
  }

  @override
  Future<Result<void>> createTask({
    required String ownerId,
    required TaskTitle title,
  }) async {
    final now = DateTime.now().toUtc();
    try {
      await _dao.insertTask(
        TasksCompanion.insert(
          id: _uuid.v4(),
          ownerId: ownerId,
          title: title.value,
          updatedAt: now,
        ),
      );
      return const ResultOk(null);
    } on Exception {
      return const ResultError(StorageFailure());
    }
  }

  @override
  Future<Result<void>> renameTask({
    required String ownerId,
    required String id,
    required TaskTitle title,
  }) => _updateExistingTask(
    ownerId: ownerId,
    id: id,
    update: (existing) => existing.copyWith(
      title: title.value,
      updatedAt: DateTime.now().toUtc(),
    ),
  );

  @override
  Future<Result<void>> setCompleted({
    required String ownerId,
    required String id,
    required bool isCompleted,
  }) => _updateExistingTask(
    ownerId: ownerId,
    id: id,
    update: (existing) => existing.copyWith(
      isCompleted: isCompleted,
      updatedAt: DateTime.now().toUtc(),
    ),
  );

  Future<Result<void>> _updateExistingTask({
    required String ownerId,
    required String id,
    required Task Function(Task existing) update,
  }) async {
    try {
      final existing = await _dao.findForOwner(ownerId, id);
      if (existing == null) return const ResultError(TaskNotFoundFailure());

      final updated = update(existing);
      if (!await _dao.updateForOwner(ownerId, updated)) {
        return const ResultError(TaskNotFoundFailure());
      }
      return const ResultOk(null);
    } on Exception {
      return const ResultError(StorageFailure());
    }
  }

  @override
  Future<Result<void>> deleteTask({
    required String ownerId,
    required String id,
  }) async {
    try {
      final deleted = await _dao.deleteForOwner(ownerId, id);
      if (deleted == 0) return const ResultError(TaskNotFoundFailure());
      return const ResultOk(null);
    } on Exception {
      return const ResultError(StorageFailure());
    }
  }

  TaskItem _toDomain(Task task) => TaskItem(
    id: task.id,
    ownerId: task.ownerId,
    title: task.title,
    isCompleted: task.isCompleted,
    updatedAt: task.updatedAt,
  );
}

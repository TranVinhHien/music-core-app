import 'package:drift/drift.dart';

import '../domain/entities/task_filter.dart';
import 'task_database.dart';
import 'tasks_table.dart';

part 'task_dao.g.dart';

/// Data access operations for the Tasks table.
@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<TaskDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  Stream<List<Task>> watchForOwner(String ownerId, TaskFilter filter) {
    final query = select(tasks)
      ..where((row) => row.ownerId.equals(ownerId))
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]);

    switch (filter) {
      case TaskFilter.all:
        break;
      case TaskFilter.active:
        query.where((row) => row.isCompleted.equals(false));
      case TaskFilter.completed:
        query.where((row) => row.isCompleted.equals(true));
    }

    return query.watch();
  }

  Future<Task?> findForOwner(String ownerId, String id) =>
      (select(
            tasks,
          )..where((task) => task.ownerId.equals(ownerId) & task.id.equals(id)))
          .getSingleOrNull();

  Future<void> insertTask(TasksCompanion task) => into(tasks).insert(task);

  Future<bool> updateForOwner(String ownerId, Task task) async {
    final updatedRows =
        await (update(tasks)..where(
              (row) => row.ownerId.equals(ownerId) & row.id.equals(task.id),
            ))
            .write(
              TasksCompanion(
                title: Value(task.title),
                isCompleted: Value(task.isCompleted),
                updatedAt: Value(task.updatedAt),
              ),
            );
    return updatedRows == 1;
  }

  Future<int> deleteForOwner(String ownerId, String id) => (delete(
    tasks,
  )..where((task) => task.ownerId.equals(ownerId) & task.id.equals(id))).go();
}

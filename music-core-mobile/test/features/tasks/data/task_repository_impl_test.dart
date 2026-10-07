import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/tasks/data/task_database.dart';
import 'package:flutter_clean_architecture_example/features/tasks/data/task_repository_impl.dart';
import 'package:flutter_clean_architecture_example/features/tasks/domain/entities/task_filter.dart';
import 'package:flutter_clean_architecture_example/features/tasks/domain/entities/task_item.dart';
import 'package:flutter_clean_architecture_example/features/tasks/domain/failures/task_failure.dart';
import 'package:flutter_clean_architecture_example/features/tasks/domain/repositories/task_repository.dart';
import 'package:flutter_clean_architecture_example/features/tasks/domain/value_objects/task_title.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TaskDatabase database;
  late TaskRepository repository;

  setUp(() {
    database = TaskDatabase.forTesting();
    repository = TaskRepositoryImpl(database);
  });

  tearDown(() => database.close());

  test('persists CRUD changes and applies filters', () async {
    final created = await repository.createTask(
      ownerId: 'alice',
      title: _title('First task'),
    );
    expect(created, isA<ResultOk<void>>());
    final task = (await _read(repository, 'alice', TaskFilter.active)).single;

    expect(task.ownerId, 'alice');
    expect(task.isCompleted, isFalse);
    expect(
      (await _read(repository, 'alice', TaskFilter.active)).single.id,
      task.id,
    );

    final renamed = await repository.renameTask(
      ownerId: 'alice',
      id: task.id,
      title: _title('Renamed task'),
    );
    expect(renamed, isA<ResultOk<void>>());
    expect(
      (await _read(repository, 'alice', TaskFilter.active)).single.title,
      'Renamed task',
    );

    final completed = await repository.setCompleted(
      ownerId: 'alice',
      id: task.id,
      isCompleted: true,
    );
    expect(completed, isA<ResultOk<void>>());
    expect(await _read(repository, 'alice', TaskFilter.active), isEmpty);
    expect(
      (await _read(repository, 'alice', TaskFilter.completed)).single.id,
      task.id,
    );

    final deleted = await repository.deleteTask(ownerId: 'alice', id: task.id);
    expect(deleted, isA<ResultOk<void>>());
    expect(await _read(repository, 'alice', TaskFilter.all), isEmpty);
  });

  test('does not allow one account to mutate another account task', () async {
    final created = await repository.createTask(
      ownerId: 'alice',
      title: _title('Private task'),
    );
    expect(created, isA<ResultOk<void>>());
    final task = (await _read(repository, 'alice', TaskFilter.all)).single;

    final rename = await repository.renameTask(
      ownerId: 'bob',
      id: task.id,
      title: _title('Not allowed'),
    );
    final delete = await repository.deleteTask(ownerId: 'bob', id: task.id);

    expect(rename, isA<ResultError<void>>());
    expect((rename as ResultError).failure, isA<TaskNotFoundFailure>());
    expect(delete, isA<ResultError<void>>());
    expect((delete as ResultError).failure, isA<TaskNotFoundFailure>());
    expect(
      (await _read(repository, 'alice', TaskFilter.all)).single.title,
      'Private task',
    );
    expect(await _read(repository, 'bob', TaskFilter.all), isEmpty);
  });

  test('orders tasks by the most recently updated timestamp', () async {
    await database.taskDao.insertTask(
      TasksCompanion.insert(
        id: 'older',
        ownerId: 'alice',
        title: 'Older task',
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await database.taskDao.insertTask(
      TasksCompanion.insert(
        id: 'newer',
        ownerId: 'alice',
        title: 'Newer task',
        updatedAt: DateTime.utc(2026, 1, 2),
      ),
    );

    final tasks = await _read(repository, 'alice', TaskFilter.all);

    expect(tasks.map((task) => task.id), ['newer', 'older']);
  });
}

Future<List<TaskItem>> _read(
  TaskRepository repository,
  String ownerId,
  TaskFilter filter,
) async {
  return repository.watchTasks(ownerId: ownerId, filter: filter).first;
}

TaskTitle _title(String value) {
  final result = TaskTitle.create(value);
  return switch (result) {
    ResultOk(value: final title) => title,
    ResultError(failure: final failure) => fail('Invalid test title: $failure'),
  };
}

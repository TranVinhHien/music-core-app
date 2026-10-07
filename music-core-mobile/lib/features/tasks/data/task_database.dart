import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'task_dao.dart';
import 'tasks_table.dart';

part 'task_database.g.dart';

/// The local SQLite database for the Tasks feature.
@DriftDatabase(tables: [Tasks], daos: [TaskDao])
class TaskDatabase extends _$TaskDatabase {
  TaskDatabase({required String name}) : super(driftDatabase(name: name));

  /// Creates an in-memory database for repository tests.
  TaskDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

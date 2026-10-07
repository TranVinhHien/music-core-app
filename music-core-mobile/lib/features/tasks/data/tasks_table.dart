import 'package:drift/drift.dart';

/// SQLite table containing the local task write model.
class Tasks extends Table {
  TextColumn get id => text()();

  TextColumn get ownerId => text()();

  TextColumn get title => text()();

  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

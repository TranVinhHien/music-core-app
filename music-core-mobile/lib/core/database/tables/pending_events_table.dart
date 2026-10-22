import 'package:drift/drift.dart';

class PendingEvents extends Table {
  TextColumn get eventId => text()();
  TextColumn get eventType => text()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get sessionId => text().nullable()();
  TextColumn get trackId => text().nullable()();
  TextColumn get sourceJson => text().nullable()();
  TextColumn get propertiesJson => text()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {eventId};
}

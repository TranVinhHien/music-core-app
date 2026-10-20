import 'package:drift/drift.dart';

/// SQLite table for caching and persisting user favorite tracks offline.
class LocalFavorites extends Table {
  TextColumn get trackId => text()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {trackId};
}

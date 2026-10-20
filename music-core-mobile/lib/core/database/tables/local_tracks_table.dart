import 'package:drift/drift.dart';

/// SQLite table for caching and persisting catalog tracks & offline downloads.
class LocalTracks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artistName => text()();
  TextColumn get albumTitle => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get coverImageUrl => text().nullable()();
  TextColumn get fileUrl => text().nullable()();
  BoolColumn get isDownloaded => boolean().withDefault(const Constant(false))();
  TextColumn get localFilePath => text().nullable()();
  IntColumn get fileSizeBytes => integer().nullable()();
  DateTimeColumn get downloadedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

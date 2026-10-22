import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/local_favorites_table.dart';
import 'tables/local_playlists_table.dart';
import 'tables/local_tracks_table.dart';
import 'tables/pending_events_table.dart';

part 'music_database.g.dart';

/// Central SQLite Database for music catalog caching, offline playlists, and downloads.
@DriftDatabase(tables: [
  LocalTracks,
  LocalPlaylists,
  LocalPlaylistTracks,
  LocalFavorites,
  PendingEvents,
])
class MusicDatabase extends _$MusicDatabase {
  MusicDatabase({required String name}) : super(driftDatabase(name: name));

  /// In-memory constructor for unit tests.
  MusicDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(pendingEvents);
          }
        },
      );

  // ---------------------------------------------------------------------------
  // Pending Listening Events Operations
  // ---------------------------------------------------------------------------

  Future<void> insertPendingEvent(PendingEventsCompanion event) async {
    await into(pendingEvents).insertOnConflictUpdate(event);
  }

  Future<List<PendingEvent>> getPendingEvents({int limit = 100}) {
    return (select(pendingEvents)
          ..orderBy([
            (PendingEvents t) =>
                OrderingTerm(expression: t.occurredAt, mode: OrderingMode.asc),
          ])
          ..limit(limit))
        .get();
  }

  Future<int> deletePendingEvents(List<String> eventIds) {
    if (eventIds.isEmpty) return Future.value(0);
    return (delete(pendingEvents)
          ..where((PendingEvents t) => t.eventId.isIn(eventIds)))
        .go();
  }

  Future<int> countPendingEvents() async {
    final countExp = pendingEvents.eventId.count();
    final query = selectOnly(pendingEvents)..addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Tracks & Downloads Operations
  // ---------------------------------------------------------------------------

  /// Caches or updates tracks from remote API without overwriting download status.
  Future<void> upsertTracks(List<LocalTracksCompanion> tracks) async {
    await batch((Batch b) {
      for (final track in tracks) {
        b.insert(
          localTracks,
          track,
          onConflict: DoUpdate<LocalTracks, LocalTrack>(
            (LocalTracks _) => LocalTracksCompanion(
              title: track.title,
              artistName: track.artistName,
              albumTitle: track.albumTitle,
              durationMs: track.durationMs,
              coverImageUrl: track.coverImageUrl,
              fileUrl: track.fileUrl,
              updatedAt: const Value.absent(),
            ),
          ),
        );
      }
    });
  }

  /// Marks a track as downloaded with its local file path and size.
  Future<void> markTrackDownloaded({
    required String trackId,
    required String localFilePath,
    required int fileSizeBytes,
  }) async {
    await (update(localTracks)..where((LocalTracks t) => t.id.equals(trackId)))
        .write(
      LocalTracksCompanion(
        isDownloaded: const Value(true),
        localFilePath: Value(localFilePath),
        fileSizeBytes: Value(fileSizeBytes),
        downloadedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Clears downloaded status and path for a track.
  Future<void> removeTrackDownload(String trackId) async {
    await (update(localTracks)..where((LocalTracks t) => t.id.equals(trackId)))
        .write(
      const LocalTracksCompanion(
        isDownloaded: Value(false),
        localFilePath: Value(null),
        fileSizeBytes: Value(0),
        downloadedAt: Value(null),
      ),
    );
  }

  /// Streams all tracks that have been downloaded for offline playback.
  Stream<List<LocalTrack>> watchDownloadedTracks() {
    return (select(localTracks)
          ..where((LocalTracks t) => t.isDownloaded.equals(true))
          ..orderBy([(LocalTracks t) => OrderingTerm.desc(t.downloadedAt)]))
        .watch();
  }

  /// Retrieves all downloaded tracks once.
  Future<List<LocalTrack>> getDownloadedTracks() {
    return (select(localTracks)
          ..where((LocalTracks t) => t.isDownloaded.equals(true))
          ..orderBy([(LocalTracks t) => OrderingTerm.desc(t.downloadedAt)]))
        .get();
  }

  /// Finds a local track by its ID.
  Future<LocalTrack?> findTrackById(String trackId) {
    return (select(localTracks)..where((LocalTracks t) => t.id.equals(trackId)))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // Playlists Operations
  // ---------------------------------------------------------------------------

  /// Caches remote playlists into SQLite.
  Future<void> upsertPlaylists(List<LocalPlaylistsCompanion> playlists) async {
    await batch((Batch b) {
      for (final p in playlists) {
        b.insert(
          localPlaylists,
          p,
          onConflict: DoUpdate<LocalPlaylists, LocalPlaylist>(
            (LocalPlaylists _) => LocalPlaylistsCompanion(
              name: p.name,
              description: p.description,
              coverImageUrl: p.coverImageUrl,
              tracksCount: p.tracksCount,
              updatedAt: Value(DateTime.now()),
            ),
          ),
        );
      }
    });
  }

  /// Streams all cached playlists.
  Stream<List<LocalPlaylist>> watchPlaylists() {
    return (select(localPlaylists)
          ..orderBy([(LocalPlaylists p) => OrderingTerm.desc(p.updatedAt)]))
        .watch();
  }

  /// Sets the tracks for an offline playlist.
  Future<void> setPlaylistTracks(
    String playlistId,
    List<String> trackIds,
  ) async {
    await transaction(() async {
      await (delete(localPlaylistTracks)
            ..where((LocalPlaylistTracks t) => t.playlistId.equals(playlistId)))
          .go();
      for (int i = 0; i < trackIds.length; i++) {
        await into(localPlaylistTracks).insert(
          LocalPlaylistTracksCompanion(
            playlistId: Value(playlistId),
            trackId: Value(trackIds[i]),
            position: Value(i + 1),
          ),
        );
      }
    });
  }

  /// Retrieves tracks belonging to a playlist.
  Future<List<LocalTrack>> getTracksForPlaylist(String playlistId) async {
    final query = select(localTracks).join([
      innerJoin(
        localPlaylistTracks,
        localPlaylistTracks.trackId.equalsExp(localTracks.id),
      ),
    ])
      ..where(localPlaylistTracks.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm.asc(localPlaylistTracks.position)]);

    final rows = await query.get();
    return rows.map((TypedResult r) => r.readTable(localTracks)).toList();
  }

  // ---------------------------------------------------------------------------
  // Favorites Operations
  // ---------------------------------------------------------------------------

  /// Caches favorite track IDs.
  Future<void> setFavoriteTracks(List<String> trackIds) async {
    await transaction(() async {
      await delete(localFavorites).go();
      for (final tid in trackIds) {
        await into(localFavorites).insert(
          LocalFavoritesCompanion(trackId: Value(tid)),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Streams favorite tracks joined with track metadata.
  Stream<List<LocalTrack>> watchFavoriteTracks() {
    final query = select(localTracks).join([
      innerJoin(
        localFavorites,
        localFavorites.trackId.equalsExp(localTracks.id),
      ),
    ])..orderBy([OrderingTerm.desc(localFavorites.addedAt)]);

    return query.watch().map(
          (List<TypedResult> rows) =>
              rows.map((TypedResult r) => r.readTable(localTracks)).toList(),
        );
  }

  /// Gets favorite tracks joined with track metadata.
  Future<List<LocalTrack>> getFavoriteTracks() async {
    final query = select(localTracks).join([
      innerJoin(
        localFavorites,
        localFavorites.trackId.equalsExp(localTracks.id),
      ),
    ])..orderBy([OrderingTerm.desc(localFavorites.addedAt)]);

    final rows = await query.get();
    return rows.map((TypedResult r) => r.readTable(localTracks)).toList();
  }
}

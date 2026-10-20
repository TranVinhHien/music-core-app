import 'package:drift/drift.dart';

import '../../../../core/database/music_database.dart';
import '../../../catalog/domain/entities/track_entity.dart';
import '../../../library/domain/entities/playlist_entity.dart';
import '../../domain/repositories/offline_repository.dart';
import '../offline_download_service.dart';

class OfflineRepositoryImpl implements OfflineRepository {
  const OfflineRepositoryImpl({
    required this.database,
    required this.downloadService,
  });

  final MusicDatabase database;
  final OfflineDownloadService downloadService;

  TrackEntity _toTrackEntity(LocalTrack row) {
    final isPhysicallyPresent =
        row.isDownloaded && downloadService.fileExists(row.localFilePath);

    return TrackEntity(
      id: row.id,
      title: row.title,
      artistName: row.artistName,
      albumTitle: row.albumTitle,
      durationMs: row.durationMs,
      coverImageUrl: row.coverImageUrl,
      fileUrl: row.fileUrl,
      localFilePath: isPhysicallyPresent ? row.localFilePath : null,
      fileSizeBytes: isPhysicallyPresent ? row.fileSizeBytes : 0,
      isDownloaded: isPhysicallyPresent,
    );
  }

  LocalTracksCompanion _toTrackCompanion(TrackEntity entity) {
    return LocalTracksCompanion(
      id: Value(entity.id),
      title: Value(entity.title),
      artistName: Value(entity.artistName),
      albumTitle: Value(entity.albumTitle),
      durationMs: Value(entity.durationMs),
      coverImageUrl: Value(entity.coverImageUrl),
      fileUrl: Value(entity.fileUrl),
      isDownloaded: Value(entity.isDownloaded),
      localFilePath: Value(entity.localFilePath),
      fileSizeBytes: Value(entity.fileSizeBytes),
    );
  }

  PlaylistEntity _toPlaylistEntity(LocalPlaylist row) {
    return PlaylistEntity(
      id: row.id,
      userId: row.userId ?? '',
      name: row.name,
      description: row.description,
      coverImageUrl: row.coverImageUrl,
      visibility: row.visibility,
      trackCount: row.tracksCount,
      createdAt: row.createdAt ?? DateTime.now(),
      updatedAt: row.updatedAt,
    );
  }

  @override
  Stream<List<TrackEntity>> watchDownloadedTracks() {
    return database.watchDownloadedTracks().map(
          (List<LocalTrack> rows) => rows.map(_toTrackEntity).toList(),
        );
  }

  @override
  Future<List<TrackEntity>> getDownloadedTracks() async {
    final rows = await database.getDownloadedTracks();
    return rows.map(_toTrackEntity).toList();
  }

  @override
  Future<TrackEntity?> getTrackById(String trackId) async {
    final row = await database.findTrackById(trackId);
    if (row == null) return null;
    return _toTrackEntity(row);
  }

  @override
  Future<void> downloadTrack(
    TrackEntity track, {
    void Function(int received, int total)? onProgress,
  }) async {
    if (track.fileUrl == null || track.fileUrl!.trim().isEmpty) {
      throw Exception('Không tìm thấy link tải của bài hát');
    }

    // 1. Ensure track metadata is cached in SQLite
    await database.upsertTracks([_toTrackCompanion(track)]);

    // 2. Download audio file to local storage
    final downloadResult = await downloadService.downloadTrack(
      trackId: track.id,
      remoteUrl: track.fileUrl!,
      onProgress: onProgress,
    );

    // 3. Mark track as downloaded in SQLite
    await database.markTrackDownloaded(
      trackId: track.id,
      localFilePath: downloadResult.localPath,
      fileSizeBytes: downloadResult.fileSizeBytes,
    );
  }

  @override
  Future<void> removeDownloadedTrack(String trackId) async {
    final row = await database.findTrackById(trackId);
    if (row != null && row.localFilePath != null) {
      await downloadService.deleteTrackFile(row.localFilePath);
    }
    await database.removeTrackDownload(trackId);
  }

  @override
  Future<void> cacheCatalogTracks(List<TrackEntity> tracks) async {
    final companions = tracks.map(_toTrackCompanion).toList();
    await database.upsertTracks(companions);
  }

  @override
  Future<void> cachePlaylists(List<PlaylistEntity> playlists) async {
    final companions = playlists.map((p) {
      return LocalPlaylistsCompanion(
        id: Value(p.id),
        userId: Value(p.userId),
        name: Value(p.name),
        description: Value(p.description),
        coverImageUrl: Value(p.coverImageUrl),
        visibility: Value(p.visibility),
        tracksCount: Value(p.trackCount),
        createdAt: Value(p.createdAt ?? DateTime.now()),
        updatedAt: Value(p.updatedAt ?? DateTime.now()),
      );
    }).toList();
    await database.upsertPlaylists(companions);
  }

  @override
  Stream<List<PlaylistEntity>> watchOfflinePlaylists() {
    return database.watchPlaylists().map(
          (List<LocalPlaylist> rows) => rows.map(_toPlaylistEntity).toList(),
        );
  }

  @override
  Future<void> cachePlaylistTracks(
    String playlistId,
    List<TrackEntity> tracks,
  ) async {
    await cacheCatalogTracks(tracks);
    await database.setPlaylistTracks(
      playlistId,
      tracks.map((t) => t.id).toList(),
    );
  }

  @override
  Future<List<TrackEntity>> getTracksForPlaylist(String playlistId) async {
    final rows = await database.getTracksForPlaylist(playlistId);
    return rows.map(_toTrackEntity).toList();
  }

  @override
  Future<void> cacheFavorites(List<TrackEntity> favorites) async {
    await cacheCatalogTracks(favorites);
    await database.setFavoriteTracks(favorites.map((f) => f.id).toList());
  }

  @override
  Stream<List<TrackEntity>> watchOfflineFavorites() {
    return database.watchFavoriteTracks().map(
          (List<LocalTrack> rows) => rows.map(_toTrackEntity).toList(),
        );
  }
}

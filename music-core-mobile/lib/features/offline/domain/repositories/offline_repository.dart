import '../../../catalog/domain/entities/track_entity.dart';
import '../../../library/domain/entities/playlist_entity.dart';

abstract interface class OfflineRepository {
  /// Stream of all downloaded tracks ready for offline playback.
  Stream<List<TrackEntity>> watchDownloadedTracks();

  /// Retrieves list of all downloaded tracks.
  Future<List<TrackEntity>> getDownloadedTracks();

  /// Gets a single track from local SQLite database.
  Future<TrackEntity?> getTrackById(String trackId);

  /// Downloads an audio track to local disk and marks it in SQLite.
  Future<void> downloadTrack(
    TrackEntity track, {
    void Function(int received, int total)? onProgress,
  });

  /// Deletes a downloaded track from local disk and updates SQLite.
  Future<void> removeDownloadedTrack(String trackId);

  /// Caches catalog tracks metadata into SQLite.
  Future<void> cacheCatalogTracks(List<TrackEntity> tracks);

  /// Caches user playlists into SQLite.
  Future<void> cachePlaylists(List<PlaylistEntity> playlists);

  /// Streams cached playlists from SQLite.
  Stream<List<PlaylistEntity>> watchOfflinePlaylists();

  /// Caches playlist tracks into SQLite.
  Future<void> cachePlaylistTracks(String playlistId, List<TrackEntity> tracks);

  /// Retrieves tracks belonging to a playlist from SQLite.
  Future<List<TrackEntity>> getTracksForPlaylist(String playlistId);

  /// Caches favorites into SQLite.
  Future<void> cacheFavorites(List<TrackEntity> favorites);

  /// Streams favorite tracks from SQLite.
  Stream<List<TrackEntity>> watchOfflineFavorites();
}

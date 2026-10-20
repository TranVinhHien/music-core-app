import '../../../../core/result.dart';
import '../../../catalog/domain/entities/track_entity.dart';
import '../entities/playlist_entity.dart';

abstract interface class LibraryRepository {
  /// Fetches playlists owned by the authenticated user.
  Future<Result<List<PlaylistEntity>>> getPlaylists({
    int page = 1,
    int limit = 20,
    String? query,
  });

  /// Creates a new playlist for the authenticated user.
  Future<Result<PlaylistEntity>> createPlaylist({
    required String name,
    String? description,
    String? coverImageUrl,
    String visibility = 'PRIVATE',
  });

  /// Fetches playlist details with its enriched tracks.
  Future<Result<PlaylistEntity>> getPlaylistDetails(String playlistId);

  /// Adds a track to a playlist.
  Future<Result<void>> addTrackToPlaylist(String playlistId, String trackId);

  /// Removes a track from a playlist.
  Future<Result<void>> removeTrackFromPlaylist(String playlistId, String trackId);

  /// Deletes a playlist.
  Future<Result<void>> deletePlaylist(String playlistId);

  /// Fetches the user's favorite tracks.
  Future<Result<List<TrackEntity>>> getFavoriteTracks({
    int page = 1,
    int limit = 50,
  });

  /// Marks a track as favorite.
  Future<Result<void>> addFavorite(String trackId);

  /// Removes a track from favorites.
  Future<Result<void>> removeFavorite(String trackId);
}

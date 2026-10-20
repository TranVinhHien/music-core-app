import '../../../../core/result.dart';
import '../../../catalog/domain/entities/track_entity.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/library_remote_data_source.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  const LibraryRepositoryImpl(this._remoteDataSource);

  final LibraryRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<PlaylistEntity>>> getPlaylists({
    int page = 1,
    int limit = 20,
    String? query,
  }) async {
    final result = await _remoteDataSource.getPlaylists(
      page: page,
      limit: limit,
      query: query,
    );

    return switch (result) {
      ResultOk(value: final rawData) => () {
          final data = (rawData is Map<String, dynamic> && rawData['data'] != null)
              ? rawData['data']
              : rawData;
          final list = (data is Map<String, dynamic>)
              ? (data['items'] ?? data['playlists'])
              : data;
          final playlists = <PlaylistEntity>[];
          if (list is List) {
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                playlists.add(PlaylistEntity.fromJson(item));
              }
            }
          }
          return ResultOk(playlists);
        }(),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }

  @override
  Future<Result<PlaylistEntity>> createPlaylist({
    required String name,
    String? description,
    String? coverImageUrl,
    String visibility = 'PRIVATE',
  }) async {
    final result = await _remoteDataSource.createPlaylist(
      name: name,
      description: description,
      coverImageUrl: coverImageUrl,
      visibility: visibility,
    );

    return switch (result) {
      ResultOk(value: final rawData) => () {
          final data = (rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>)
              ? rawData['data'] as Map<String, dynamic>
              : (rawData is Map<String, dynamic> ? rawData : null);
          if (data != null) {
            return ResultOk(PlaylistEntity.fromJson(data));
          }
          return const ResultError<PlaylistEntity>(
            ValidationFailure('Invalid playlist data returned from server'),
          );
        }(),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }

  @override
  Future<Result<PlaylistEntity>> getPlaylistDetails(String playlistId) async {
    final result = await _remoteDataSource.getPlaylistDetails(playlistId);

    return switch (result) {
      ResultOk(value: final rawData) => () {
          final data = (rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>)
              ? rawData['data'] as Map<String, dynamic>
              : (rawData is Map<String, dynamic> ? rawData : null);
          if (data != null) {
            return ResultOk(PlaylistEntity.fromJson(data));
          }
          return const ResultError<PlaylistEntity>(
            ValidationFailure('Invalid playlist detail response'),
          );
        }(),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }

  @override
  Future<Result<void>> addTrackToPlaylist(String playlistId, String trackId) async {
    final result = await _remoteDataSource.addTrackToPlaylist(playlistId, trackId);
    return switch (result) {
      ResultOk() => const ResultOk(null),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }

  @override
  Future<Result<void>> removeTrackFromPlaylist(String playlistId, String trackId) async {
    final result = await _remoteDataSource.removeTrackFromPlaylist(playlistId, trackId);
    return switch (result) {
      ResultOk() => const ResultOk(null),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }

  @override
  Future<Result<void>> deletePlaylist(String playlistId) async {
    final result = await _remoteDataSource.deletePlaylist(playlistId);
    return switch (result) {
      ResultOk() => const ResultOk(null),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }

  @override
  Future<Result<List<TrackEntity>>> getFavoriteTracks({
    int page = 1,
    int limit = 50,
  }) async {
    final result = await _remoteDataSource.getFavoriteTracks(page: page, limit: limit);

    return switch (result) {
      ResultOk(value: final rawData) => () {
          final data = (rawData is Map<String, dynamic> && rawData['data'] != null)
              ? rawData['data']
              : rawData;
          final tracks = <TrackEntity>[];
          final list = (data is Map<String, dynamic>)
              ? (data['items'] ?? data['tracks'] ?? data['favorites'])
              : data;
          if (list is List) {
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                // If nested as item['track'], parse it
                if (item['track'] is Map<String, dynamic>) {
                  tracks.add(TrackEntity.fromJson(item['track'] as Map<String, dynamic>));
                } else {
                  tracks.add(TrackEntity.fromJson(item));
                }
              }
            }
          }
          return ResultOk(tracks);
        }(),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }

  @override
  Future<Result<void>> addFavorite(String trackId) async {
    final result = await _remoteDataSource.addFavorite(trackId);
    return switch (result) {
      ResultOk() => const ResultOk(null),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }

  @override
  Future<Result<void>> removeFavorite(String trackId) async {
    final result = await _remoteDataSource.removeFavorite(trackId);
    return switch (result) {
      ResultOk() => const ResultOk(null),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }
}

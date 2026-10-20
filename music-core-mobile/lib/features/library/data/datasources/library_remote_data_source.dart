import '../../../../core/network/api_client.dart';
import '../../../../core/result.dart';

abstract interface class LibraryRemoteDataSource {
  Future<Result<dynamic>> getPlaylists({
    int page = 1,
    int limit = 20,
    String? query,
  });

  Future<Result<dynamic>> createPlaylist({
    required String name,
    String? description,
    String? coverImageUrl,
    String visibility = 'PRIVATE',
  });

  Future<Result<dynamic>> getPlaylistDetails(String playlistId);

  Future<Result<dynamic>> addTrackToPlaylist(String playlistId, String trackId);

  Future<Result<dynamic>> removeTrackFromPlaylist(String playlistId, String trackId);

  Future<Result<dynamic>> deletePlaylist(String playlistId);

  Future<Result<dynamic>> getFavoriteTracks({
    int page = 1,
    int limit = 50,
  });

  Future<Result<dynamic>> addFavorite(String trackId);

  Future<Result<dynamic>> removeFavorite(String trackId);
}

class LibraryRemoteDataSourceImpl implements LibraryRemoteDataSource {
  const LibraryRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Result<dynamic>> getPlaylists({
    int page = 1,
    int limit = 20,
    String? query,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'order': 'desc',
    };
    if (query != null && query.trim().isNotEmpty) {
      queryParams['query'] = query.trim();
    }
    return _apiClient.get(
      '/api/v1/library/playlists',
      queryParameters: queryParams,
    );
  }

  @override
  Future<Result<dynamic>> createPlaylist({
    required String name,
    String? description,
    String? coverImageUrl,
    String visibility = 'PRIVATE',
  }) async {
    return _apiClient.post(
      '/api/v1/library/playlists',
      data: {
        'name': name.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (coverImageUrl != null && coverImageUrl.trim().isNotEmpty)
          'coverImageUrl': coverImageUrl.trim(),
        'visibility': visibility,
      },
    );
  }

  @override
  Future<Result<dynamic>> getPlaylistDetails(String playlistId) async {
    return _apiClient.get('/api/v1/library/playlists/$playlistId');
  }

  @override
  Future<Result<dynamic>> addTrackToPlaylist(String playlistId, String trackId) async {
    return _apiClient.post(
      '/api/v1/library/playlists/$playlistId/tracks',
      data: {'trackId': trackId},
    );
  }

  @override
  Future<Result<dynamic>> removeTrackFromPlaylist(String playlistId, String trackId) async {
    return _apiClient.delete(
      '/api/v1/library/playlists/$playlistId/tracks/$trackId',
    );
  }

  @override
  Future<Result<dynamic>> deletePlaylist(String playlistId) async {
    return _apiClient.delete('/api/v1/library/playlists/$playlistId');
  }

  @override
  Future<Result<dynamic>> getFavoriteTracks({
    int page = 1,
    int limit = 50,
  }) async {
    return _apiClient.get(
      '/api/v1/library/favorites/tracks',
      queryParameters: {
        'page': page,
        'limit': limit,
        'order': 'desc',
      },
    );
  }

  @override
  Future<Result<dynamic>> addFavorite(String trackId) async {
    return _apiClient.post(
      '/api/v1/library/favorites/tracks',
      data: {'trackId': trackId},
    );
  }

  @override
  Future<Result<dynamic>> removeFavorite(String trackId) async {
    return _apiClient.delete(
      '/api/v1/library/favorites/tracks/$trackId',
    );
  }
}

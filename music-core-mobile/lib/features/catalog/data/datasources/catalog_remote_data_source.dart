import '../../../../core/network/api_client.dart';
import '../../../../core/result.dart';

abstract interface class CatalogRemoteDataSource {
  Future<Result<dynamic>> getTracks({
    String? query,
    int page = 1,
    int limit = 20,
  });

  Future<Result<dynamic>> getTrackById(String id);

  Future<Result<dynamic>> searchCatalog({
    required String query,
    int page = 1,
    int limit = 10,
    String type = 'all',
  });

  Future<Result<dynamic>> getAlbumById(String id);

  Future<Result<dynamic>> getArtistById(String id);

  Future<Result<dynamic>> getRandomTrack({
    String? excludeTrackId,
    List<String>? excludeTrackIds,
    String? genreId,
  });
}

class CatalogRemoteDataSourceImpl implements CatalogRemoteDataSource {
  const CatalogRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Result<dynamic>> getTracks({
    String? query,
    int page = 1,
    int limit = 20,
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
      '/api/v1/catalog/tracks',
      queryParameters: queryParams,
    );
  }

  @override
  Future<Result<dynamic>> getTrackById(String id) async {
    return _apiClient.get('/api/v1/catalog/tracks/$id');
  }

  @override
  Future<Result<dynamic>> searchCatalog({
    required String query,
    int page = 1,
    int limit = 10,
    String type = 'all',
  }) async {
    final queryParams = <String, dynamic>{
      'query': query.trim(),
      'page': page,
      'limit': limit,
      'type': type,
    };

    return _apiClient.get(
      '/api/v1/catalog/search',
      queryParameters: queryParams,
    );
  }

  @override
  Future<Result<dynamic>> getAlbumById(String id) async {
    return _apiClient.get('/api/v1/catalog/albums/$id');
  }

  @override
  Future<Result<dynamic>> getArtistById(String id) async {
    return _apiClient.get('/api/v1/catalog/artists/$id');
  }

  @override
  Future<Result<dynamic>> getRandomTrack({
    String? excludeTrackId,
    List<String>? excludeTrackIds,
    String? genreId,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': 1,
    };
    if (excludeTrackId != null && excludeTrackId.trim().isNotEmpty) {
      queryParams['excludeTrackId'] = excludeTrackId.trim();
    }
    if (excludeTrackIds != null && excludeTrackIds.isNotEmpty) {
      queryParams['excludeTrackIds'] = excludeTrackIds.join(',');
    }
    if (genreId != null && genreId.trim().isNotEmpty) {
      queryParams['genreId'] = genreId.trim();
    }

    return _apiClient.get(
      '/api/v1/catalog/tracks/random',
      queryParameters: queryParams,
    );
  }
}

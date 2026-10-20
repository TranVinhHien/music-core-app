import '../../../../core/network/api_client.dart';
import '../../../../core/result.dart';

abstract interface class CatalogRemoteDataSource {
  Future<Result<dynamic>> getTracks({
    String? query,
    int page = 1,
    int limit = 20,
  });

  Future<Result<dynamic>> getTrackById(String id);
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
}

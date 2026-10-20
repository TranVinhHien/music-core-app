import '../../../../core/result.dart';
import '../../domain/entities/track_entity.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_data_source.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl(this._remoteDataSource);

  final CatalogRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<TrackEntity>>> getTracks({
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _remoteDataSource.getTracks(
      query: query,
      page: page,
      limit: limit,
    );

    return switch (result) {
      ResultOk(value: final rawData) => () {
          final data = (rawData is Map<String, dynamic> && rawData['data'] != null)
              ? rawData['data']
              : rawData;
          final tracks = <TrackEntity>[];
          final list = (data is Map<String, dynamic>)
              ? (data['items'] ?? data['tracks'])
              : data;
          if (list is List) {
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                tracks.add(TrackEntity.fromJson(item));
              }
            }
          }
          return ResultOk(tracks);
        }(),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }

  @override
  Future<Result<TrackEntity>> getTrackById(String id) async {
    final result = await _remoteDataSource.getTrackById(id);

    return switch (result) {
      ResultOk(value: final rawData) => () {
          final data = (rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>)
              ? rawData['data'] as Map<String, dynamic>
              : (rawData is Map<String, dynamic> ? rawData : null);
          if (data != null) {
            return ResultOk(TrackEntity.fromJson(data));
          }
          return const ResultError<TrackEntity>(
            ValidationFailure('Invalid track data returned from server'),
          );
        }(),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }
}

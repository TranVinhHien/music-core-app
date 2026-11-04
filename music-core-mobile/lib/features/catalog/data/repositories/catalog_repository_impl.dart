import '../../../../core/result.dart';
import '../../domain/entities/album_entity.dart';
import '../../domain/entities/artist_entity.dart';
import '../../domain/entities/catalog_search_result.dart';
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

  @override
  Future<Result<CatalogSearchResult>> searchCatalog({
    required String query,
    int page = 1,
    int limit = 10,
    String type = 'all',
  }) async {
    final result = await _remoteDataSource.searchCatalog(
      query: query,
      page: page,
      limit: limit,
      type: type,
    );

    return switch (result) {
      ResultOk(value: final rawData) => () {
          final data = (rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>)
              ? rawData['data'] as Map<String, dynamic>
              : (rawData is Map<String, dynamic> ? rawData : null);

          if (data == null) {
            return const ResultError<CatalogSearchResult>(
              ValidationFailure('Invalid or empty search response body'),
            );
          }

          final searchResult = CatalogSearchResult.fromJson(data);
          return ResultOk(searchResult);
        }(),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }

  @override
  Future<Result<AlbumEntity>> getAlbumById(String id) async {
    final result = await _remoteDataSource.getAlbumById(id);

    return switch (result) {
      ResultOk(value: final rawData) => () {
          final data = (rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>)
              ? rawData['data'] as Map<String, dynamic>
              : (rawData is Map<String, dynamic> ? rawData : null);

          if (data != null) {
            return ResultOk(AlbumEntity.fromJson(data));
          }
          return const ResultError<AlbumEntity>(
            ValidationFailure('Invalid album data returned from server'),
          );
        }(),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }

  @override
  Future<Result<ArtistEntity>> getArtistById(String id) async {
    final result = await _remoteDataSource.getArtistById(id);

    return switch (result) {
      ResultOk(value: final rawData) => () {
          final data = (rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>)
              ? rawData['data'] as Map<String, dynamic>
              : (rawData is Map<String, dynamic> ? rawData : null);

          if (data != null) {
            return ResultOk(ArtistEntity.fromJson(data));
          }
          return const ResultError<ArtistEntity>(
            ValidationFailure('Invalid artist data returned from server'),
          );
        }(),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }

  @override
  Future<Result<TrackEntity>> getRandomTrack({
    String? excludeTrackId,
    List<String>? excludeTrackIds,
    String? genreId,
  }) async {
    final result = await _remoteDataSource.getRandomTrack(
      excludeTrackId: excludeTrackId,
      excludeTrackIds: excludeTrackIds,
      genreId: genreId,
    );

    return switch (result) {
      ResultOk(value: final rawData) => () {
          final data = (rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>)
              ? rawData['data'] as Map<String, dynamic>
              : (rawData is Map<String, dynamic> ? rawData : null);

          if (data != null) {
            return ResultOk(TrackEntity.fromJson(data));
          }
          return const ResultError<TrackEntity>(
            ValidationFailure('Invalid random track data returned from server'),
          );
        }(),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }
}

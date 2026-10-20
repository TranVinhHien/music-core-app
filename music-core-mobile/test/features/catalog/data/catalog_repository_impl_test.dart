import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/catalog/data/datasources/catalog_remote_data_source.dart';
import 'package:flutter_clean_architecture_example/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:flutter_clean_architecture_example/features/catalog/domain/entities/track_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CatalogRepositoryImpl', () {
    test('getTracks parses tracks and returns ResultOk on success', () async {
      final mockSource = _MockCatalogRemoteDataSource(
        getTracksResult: const ResultOk({
          'data': {
            'tracks': [
              {
                'id': 't1',
                'title': 'Song 1',
                'durationMs': 180000,
                'fileUrl': 'http://example.com/audio.mp3',
                'trackArtists': [
                  {
                    'artist': {'name': 'Artist 1'}
                  }
                ],
              },
            ],
          },
        }),
      );
      final repository = CatalogRepositoryImpl(mockSource);

      final result = await repository.getTracks(page: 1, limit: 10);

      expect(result, isA<ResultOk<List<TrackEntity>>>());
      final tracks = (result as ResultOk<List<TrackEntity>>).value;
      expect(tracks.length, 1);
      expect(tracks.first.title, 'Song 1');
      expect(tracks.first.artistName, 'Artist 1');
    });

    test('getTracks propagates error when remote data source returns ResultError', () async {
      final mockSource = _MockCatalogRemoteDataSource(
        getTracksResult: const ResultError(ServerFailure('Catalog offline')),
      );
      final repository = CatalogRepositoryImpl(mockSource);

      final result = await repository.getTracks();

      expect(result, isA<ResultError<List<TrackEntity>>>());
      final error = result as ResultError<List<TrackEntity>>;
      expect(error.failure, isA<ServerFailure>());
    });

    test('getTrackById returns ResultOk when track exists', () async {
      final mockSource = _MockCatalogRemoteDataSource(
        getTrackByIdResult: const ResultOk({
          'data': {
            'id': 't1',
            'title': 'Track Detail',
            'durationMs': 200000,
            'fileUrl': 'http://example.com/audio.mp3',
            'trackArtists': [
              {
                'artist': {'name': 'Artist Detail'}
              }
            ],
          },
        }),
      );
      final repository = CatalogRepositoryImpl(mockSource);

      final result = await repository.getTrackById('t1');

      expect(result, isA<ResultOk<TrackEntity>>());
      final track = (result as ResultOk<TrackEntity>).value;
      expect(track.id, 't1');
      expect(track.title, 'Track Detail');
    });
  });
}

class _MockCatalogRemoteDataSource implements CatalogRemoteDataSource {
  _MockCatalogRemoteDataSource({
    this.getTracksResult,
    this.getTrackByIdResult,
  });

  final Result<dynamic>? getTracksResult;
  final Result<dynamic>? getTrackByIdResult;

  @override
  Future<Result<dynamic>> getTracks({
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    return getTracksResult ?? const ResultOk({'data': {'tracks': <dynamic>[]}});
  }

  @override
  Future<Result<dynamic>> getTrackById(String id) async {
    return getTrackByIdResult ??
        ResultOk({
          'data': {
            'id': id,
            'title': 'Default Track',
          },
        });
  }
}

import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/catalog/data/datasources/catalog_remote_data_source.dart';
import 'package:flutter_clean_architecture_example/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:flutter_clean_architecture_example/features/catalog/domain/entities/album_entity.dart';
import 'package:flutter_clean_architecture_example/features/catalog/domain/entities/artist_entity.dart';
import 'package:flutter_clean_architecture_example/features/catalog/domain/entities/catalog_search_result.dart';
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

    test('searchCatalog parses 3 sections (tracks, albums, artists) successfully', () async {
      final mockSource = _MockCatalogRemoteDataSource(
        searchCatalogResult: const ResultOk({
          'data': {
            'tracks': {
              'items': [
                {
                  'id': 'tr-1',
                  'title': 'Search Track',
                  'durationMs': 120000,
                  'artists': [
                    {'id': 'ar-1', 'name': 'Search Artist'}
                  ],
                }
              ],
              'total': 1,
            },
            'albums': {
              'items': [
                {
                  'id': 'al-1',
                  'title': 'Search Album',
                  'artists': [
                    {'id': 'ar-1', 'name': 'Search Artist'}
                  ],
                  'totalTracks': 8,
                }
              ],
              'total': 1,
            },
            'artists': {
              'items': [
                {
                  'id': 'ar-1',
                  'name': 'Search Artist',
                  'bio': 'A famous musician',
                }
              ],
              'total': 1,
            },
          },
        }),
      );
      final repository = CatalogRepositoryImpl(mockSource);

      final result = await repository.searchCatalog(query: 'Search');

      expect(result, isA<ResultOk<CatalogSearchResult>>());
      final data = (result as ResultOk<CatalogSearchResult>).value;
      expect(data.totalFound, 3);
      expect(data.tracks.items.first.title, 'Search Track');
      expect(data.tracks.items.first.artistName, 'Search Artist');
      expect(data.albums.items.first.title, 'Search Album');
      expect(data.albums.items.first.totalTracks, 8);
      expect(data.artists.items.first.name, 'Search Artist');
      expect(data.artists.items.first.bio, 'A famous musician');
    });

    test('getAlbumById returns full album details', () async {
      final mockSource = _MockCatalogRemoteDataSource(
        getAlbumByIdResult: const ResultOk({
          'data': {
            'id': 'alb-99',
            'title': 'Master Album',
            'releaseDate': '2024-01-01T00:00:00.000Z',
            'albumArtists': [
              {
                'artist': {'id': 'art-99', 'name': 'Master Artist'}
              }
            ],
            'tracks': [
              {
                'id': 'trk-1',
                'title': 'Master Song 1',
                'durationMs': 180000,
              }
            ],
          },
        }),
      );
      final repository = CatalogRepositoryImpl(mockSource);

      final result = await repository.getAlbumById('alb-99');

      expect(result, isA<ResultOk<AlbumEntity>>());
      final album = (result as ResultOk<AlbumEntity>).value;
      expect(album.id, 'alb-99');
      expect(album.title, 'Master Album');
      expect(album.artistName, 'Master Artist');
      expect(album.tracks.length, 1);
      expect(album.tracks.first.title, 'Master Song 1');
    });

    test('getArtistById returns artist with discography', () async {
      final mockSource = _MockCatalogRemoteDataSource(
        getArtistByIdResult: const ResultOk({
          'data': {
            'id': 'art-100',
            'name': 'Superstar',
            'bio': 'Bio text',
            'albumArtists': [
              {
                'album': {'id': 'alb-1', 'title': 'Greatest Hits'}
              }
            ],
            'trackArtists': [
              {
                'track': {'id': 'trk-1', 'title': 'Hit Song'}
              }
            ],
          },
        }),
      );
      final repository = CatalogRepositoryImpl(mockSource);

      final result = await repository.getArtistById('art-100');

      expect(result, isA<ResultOk<ArtistEntity>>());
      final artist = (result as ResultOk<ArtistEntity>).value;
      expect(artist.id, 'art-100');
      expect(artist.name, 'Superstar');
      expect(artist.albums.length, 1);
      expect(artist.albums.first.title, 'Greatest Hits');
      expect(artist.tracks.length, 1);
      expect(artist.tracks.first.title, 'Hit Song');
    });

    test('getRandomTrack parses single track response and returns ResultOk', () async {
      final mockSource = _MockCatalogRemoteDataSource(
        getRandomTrackResult: const ResultOk({
          'data': {
            'id': 'tr-rand-1',
            'title': 'Random Hit',
            'artistName': 'Random DJ',
            'durationMs': 210000,
          },
        }),
      );
      final repository = CatalogRepositoryImpl(mockSource);

      final result = await repository.getRandomTrack(excludeTrackId: 'curr-1');

      expect(result, isA<ResultOk<TrackEntity>>());
      final track = (result as ResultOk<TrackEntity>).value;
      expect(track.id, 'tr-rand-1');
      expect(track.title, 'Random Hit');
      expect(track.artistName, 'Random DJ');
    });

    test('getRandomTrack propagates ResultError on server error', () async {
      final mockSource = _MockCatalogRemoteDataSource(
        getRandomTrackResult: const ResultError(ServerFailure('Service Unavailable')),
      );
      final repository = CatalogRepositoryImpl(mockSource);

      final result = await repository.getRandomTrack();

      expect(result, isA<ResultError<TrackEntity>>());
    });
  });
}

class _MockCatalogRemoteDataSource implements CatalogRemoteDataSource {
  _MockCatalogRemoteDataSource({
    this.getTracksResult,
    this.getTrackByIdResult,
    this.searchCatalogResult,
    this.getAlbumByIdResult,
    this.getArtistByIdResult,
    this.getRandomTrackResult,
  });

  final Result<dynamic>? getTracksResult;
  final Result<dynamic>? getTrackByIdResult;
  final Result<dynamic>? searchCatalogResult;
  final Result<dynamic>? getAlbumByIdResult;
  final Result<dynamic>? getArtistByIdResult;
  final Result<dynamic>? getRandomTrackResult;

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

  @override
  Future<Result<dynamic>> searchCatalog({
    required String query,
    int page = 1,
    int limit = 10,
    String type = 'all',
  }) async {
    return searchCatalogResult ??
        const ResultOk({
          'data': {
            'tracks': {'items': <dynamic>[], 'total': 0},
            'albums': {'items': <dynamic>[], 'total': 0},
            'artists': {'items': <dynamic>[], 'total': 0},
          },
        });
  }

  @override
  Future<Result<dynamic>> getAlbumById(String id) async {
    return getAlbumByIdResult ??
        ResultOk({
          'data': {
            'id': id,
            'title': 'Mock Album',
          },
        });
  }

  @override
  Future<Result<dynamic>> getArtistById(String id) async {
    return getArtistByIdResult ??
        ResultOk({
          'data': {
            'id': id,
            'name': 'Mock Artist',
          },
        });
  }

  @override
  Future<Result<dynamic>> getRandomTrack({
    String? excludeTrackId,
    List<String>? excludeTrackIds,
    String? genreId,
  }) async {
    return getRandomTrackResult ??
        ResultOk({
          'data': {
            'id': 'default-random',
            'title': 'Default Random Track',
          },
        });
  }
}

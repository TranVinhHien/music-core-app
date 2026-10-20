import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/catalog/domain/entities/track_entity.dart';
import 'package:flutter_clean_architecture_example/features/library/data/datasources/library_remote_data_source.dart';
import 'package:flutter_clean_architecture_example/features/library/data/repositories/library_repository_impl.dart';
import 'package:flutter_clean_architecture_example/features/library/domain/entities/playlist_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LibraryRepositoryImpl', () {
    test('getPlaylists returns mapped PlaylistEntity list on success', () async {
      final mockSource = _MockLibraryRemoteDataSource(
        getPlaylistsResult: const ResultOk({
          'data': {
            'items': [
              {
                'id': 'p1',
                'user_id': 'u1',
                'name': 'My Playlist',
                'description': 'Chill beats',
                'track_count': 5,
                'created_at': '2025-01-01T00:00:00Z',
              },
            ],
          },
        }),
      );
      final repo = LibraryRepositoryImpl(mockSource);

      final result = await repo.getPlaylists();

      expect(result, isA<ResultOk<List<PlaylistEntity>>>());
      final list = (result as ResultOk<List<PlaylistEntity>>).value;
      expect(list.length, 1);
      expect(list.first.name, 'My Playlist');
      expect(list.first.trackCount, 5);
    });

    test('getPlaylists propagates error when data source fails', () async {
      final mockSource = _MockLibraryRemoteDataSource(
        getPlaylistsResult: const ResultError(ServerFailure('Server down')),
      );
      final repo = LibraryRepositoryImpl(mockSource);

      final result = await repo.getPlaylists();

      expect(result, isA<ResultError<List<PlaylistEntity>>>());
      final err = result as ResultError<List<PlaylistEntity>>;
      expect(err.failure, isA<ServerFailure>());
    });

    test('createPlaylist creates and returns new PlaylistEntity', () async {
      final mockSource = _MockLibraryRemoteDataSource(
        createPlaylistResult: const ResultOk({
          'data': {
            'id': 'p2',
            'user_id': 'u1',
            'name': 'Workout',
            'description': 'Gym tracks',
            'created_at': '2025-01-02T00:00:00Z',
          },
        }),
      );
      final repo = LibraryRepositoryImpl(mockSource);

      final result = await repo.createPlaylist(name: 'Workout', description: 'Gym tracks');

      expect(result, isA<ResultOk<PlaylistEntity>>());
      final p = (result as ResultOk<PlaylistEntity>).value;
      expect(p.id, 'p2');
      expect(p.name, 'Workout');
    });

    test('getFavoriteTracks parses catalog-enriched tracks correctly', () async {
      final mockSource = _MockLibraryRemoteDataSource(
        getFavoriteTracksResult: const ResultOk({
          'data': [
            {
              'track_id': 't1',
              'track': {
                'id': 't1',
                'title': 'Favorite Song',
                'durationMs': 210000,
                'fileUrl': 'http://example.com/fav.mp3',
                'trackArtists': [
                  {
                    'artist': {'name': 'Star Artist'}
                  }
                ],
              },
            },
          ],
        }),
      );
      final repo = LibraryRepositoryImpl(mockSource);

      final result = await repo.getFavoriteTracks();

      expect(result, isA<ResultOk<List<TrackEntity>>>());
      final tracks = (result as ResultOk<List<TrackEntity>>).value;
      expect(tracks.length, 1);
      expect(tracks.first.title, 'Favorite Song');
    });

    test('addFavorite and removeFavorite delegate to data source', () async {
      final mockSource = _MockLibraryRemoteDataSource();
      final repo = LibraryRepositoryImpl(mockSource);

      final addResult = await repo.addFavorite('t1');
      expect(addResult, isA<ResultOk<void>>());

      final removeResult = await repo.removeFavorite('t1');
      expect(removeResult, isA<ResultOk<void>>());
    });
  });
}

class _MockLibraryRemoteDataSource implements LibraryRemoteDataSource {
  _MockLibraryRemoteDataSource({
    this.getPlaylistsResult,
    this.createPlaylistResult,
    this.getFavoriteTracksResult,
  });

  final Result<dynamic>? getPlaylistsResult;
  final Result<dynamic>? createPlaylistResult;
  final Result<dynamic>? getFavoriteTracksResult;

  @override
  Future<Result<dynamic>> getPlaylists({
    int page = 1,
    int limit = 20,
    String? query,
  }) async {
    return getPlaylistsResult ?? const ResultOk({'data': {'items': <dynamic>[]}});
  }

  @override
  Future<Result<dynamic>> createPlaylist({
    required String name,
    String? description,
    String? coverImageUrl,
    String visibility = 'PRIVATE',
  }) async {
    return createPlaylistResult ??
        ResultOk({
          'data': {
            'id': 'new_id',
            'user_id': 'u1',
            'name': name,
            'description': description,
            'created_at': '2025-01-01T00:00:00Z',
          },
        });
  }

  @override
  Future<Result<dynamic>> getPlaylistDetails(String playlistId) async {
    return ResultOk({
      'data': {
        'id': playlistId,
        'user_id': 'u1',
        'name': 'Detail Playlist',
        'tracks': <dynamic>[],
      },
    });
  }

  @override
  Future<Result<dynamic>> addTrackToPlaylist(String playlistId, String trackId) async {
    return const ResultOk(null);
  }

  @override
  Future<Result<dynamic>> removeTrackFromPlaylist(String playlistId, String trackId) async {
    return const ResultOk(null);
  }

  @override
  Future<Result<dynamic>> deletePlaylist(String playlistId) async {
    return const ResultOk(null);
  }

  @override
  Future<Result<dynamic>> getFavoriteTracks({
    int page = 1,
    int limit = 50,
  }) async {
    return getFavoriteTracksResult ?? const ResultOk({'data': <dynamic>[]});
  }

  @override
  Future<Result<dynamic>> addFavorite(String trackId) async {
    return const ResultOk(null);
  }

  @override
  Future<Result<dynamic>> removeFavorite(String trackId) async {
    return const ResultOk(null);
  }
}

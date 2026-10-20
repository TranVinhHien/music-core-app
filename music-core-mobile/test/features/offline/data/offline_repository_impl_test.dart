import 'package:flutter_clean_architecture_example/core/database/music_database.dart';
import 'package:flutter_clean_architecture_example/features/catalog/domain/entities/track_entity.dart';
import 'package:flutter_clean_architecture_example/features/library/domain/entities/playlist_entity.dart';
import 'package:flutter_clean_architecture_example/features/offline/data/offline_download_service.dart';
import 'package:flutter_clean_architecture_example/features/offline/data/repositories/offline_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDownloadService extends OfflineDownloadService {
  final Map<String, bool> existingFiles = {};

  @override
  bool fileExists(String? filePath) {
    if (filePath == null) return false;
    return existingFiles[filePath] ?? false;
  }

  @override
  Future<({String localPath, int fileSizeBytes})> downloadTrack({
    required String trackId,
    required String remoteUrl,
    void Function(int received, int total)? onProgress,
  }) async {
    final path = '/mock/offline/$trackId.mp3';
    existingFiles[path] = true;
    onProgress?.call(100, 100);
    return (localPath: path, fileSizeBytes: 1024 * 1024 * 3);
  }

  @override
  Future<void> deleteTrackFile(String? filePath) async {
    if (filePath != null) {
      existingFiles.remove(filePath);
    }
  }
}

void main() {
  late MusicDatabase database;
  late FakeDownloadService downloadService;
  late OfflineRepositoryImpl repository;

  setUp(() {
    database = MusicDatabase.forTesting();
    downloadService = FakeDownloadService();
    repository = OfflineRepositoryImpl(
      database: database,
      downloadService: downloadService,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('OfflineRepositoryImpl', () {
    const testTrack = TrackEntity(
      id: 'track_1',
      title: 'Bài Hát Test',
      artistName: 'Ca Sĩ Test',
      albumTitle: 'Album Test',
      durationMs: 210000,
      coverImageUrl: 'https://example.com/cover.jpg',
      fileUrl: 'https://example.com/song.mp3',
    );

    test('cacheCatalogTracks saves track in SQLite', () async {
      await repository.cacheCatalogTracks([testTrack]);

      final cached = await repository.getTrackById(testTrack.id);
      expect(cached, isNotNull);
      expect(cached!.title, 'Bài Hát Test');
      expect(cached.isDownloaded, isFalse);
    });

    test('downloadTrack downloads file and updates SQLite status', () async {
      await repository.downloadTrack(testTrack);

      final downloaded = await repository.getTrackById(testTrack.id);
      expect(downloaded, isNotNull);
      expect(downloaded!.isDownloaded, isTrue);
      expect(downloaded.localFilePath, '/mock/offline/track_1.mp3');
      expect(downloaded.fileSizeBytes, 3145728);

      final list = await repository.getDownloadedTracks();
      expect(list.length, 1);
      expect(list.first.id, testTrack.id);
    });

    test('removeDownloadedTrack deletes physical file and resets download status in SQLite', () async {
      await repository.downloadTrack(testTrack);
      expect(downloadService.existingFiles.isNotEmpty, isTrue);

      await repository.removeDownloadedTrack(testTrack.id);

      expect(downloadService.existingFiles.isEmpty, isTrue);
      final afterRemove = await repository.getTrackById(testTrack.id);
      expect(afterRemove, isNotNull);
      expect(afterRemove!.isDownloaded, isFalse);
      expect(afterRemove.localFilePath, isNull);
    });

    test('cachePlaylists and getTracksForPlaylist persist offline playlist mapping', () async {
      const playlist = PlaylistEntity(
        id: 'pl_1',
        userId: 'u1',
        name: 'Chill Vibes',
        trackCount: 1,
      );

      await repository.cachePlaylists([playlist]);
      await repository.cachePlaylistTracks('pl_1', [testTrack]);

      final tracksInPlaylist = await repository.getTracksForPlaylist('pl_1');
      expect(tracksInPlaylist.length, 1);
      expect(tracksInPlaylist.first.id, 'track_1');
    });

    test('cacheFavorites persists favorite tracks offline', () async {
      await repository.cacheFavorites([testTrack]);

      final favorites = await database.getFavoriteTracks();
      expect(favorites.length, 1);
      expect(favorites.first.id, 'track_1');
    });
  });
}

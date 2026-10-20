import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/audio_url_resolver.dart';

typedef DownloadProgressCallback = void Function(int receivedBytes, int totalBytes);

class OfflineDownloadService {
  OfflineDownloadService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<String> getOfflineStorageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory('${appDir.path}/offline_tracks');
    if (!await offlineDir.exists()) {
      await offlineDir.create(recursive: true);
    }
    return offlineDir.path;
  }

  /// Downloads an audio file from a remote URL to the local offline directory.
  /// Returns the absolute path and the file size in bytes.
  Future<({String localPath, int fileSizeBytes})> downloadTrack({
    required String trackId,
    required String remoteUrl,
    DownloadProgressCallback? onProgress,
  }) async {
    final resolvedUrl = AudioUrlResolver.resolve(remoteUrl);
    final storageDir = await getOfflineStorageDirectory();
    final localPath = '$storageDir/$trackId.mp3';

    // Temp file during download to avoid corrupted states
    final tempPath = '$localPath.tmp';
    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    try {
      await _dio.download(
        resolvedUrl,
        tempPath,
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(received, total);
          }
        },
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
          responseType: ResponseType.bytes,
        ),
      );

      final downloadedFile = File(tempPath);
      if (!await downloadedFile.exists()) {
        throw Exception('Download failed: file not written to disk');
      }

      // Rename temp file to final target
      final targetFile = await downloadedFile.rename(localPath);
      final size = await targetFile.length();

      return (localPath: localPath, fileSizeBytes: size);
    } catch (e) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }

  /// Deletes a downloaded local track file from disk.
  Future<void> deleteTrackFile(String? localPath) async {
    if (localPath == null || localPath.trim().isEmpty) return;
    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Checks if a file actually exists on disk.
  bool fileExists(String? localPath) {
    if (localPath == null || localPath.trim().isEmpty) return false;
    return File(localPath).existsSync();
  }
}

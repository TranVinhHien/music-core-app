import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/audio_url_resolver.dart';
import '../../features/catalog/domain/entities/track_entity.dart';

/// Service managing background pre-caching of upcoming tracks to disk.
/// This enables zero-latency track transitions without network buffering delays.
class AudioPrecacheService {
  AudioPrecacheService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  final Map<String, String> _cachedPaths = {}; // trackId -> localFilePath
  final Set<String> _inProgressTrackIds = {};
  final List<String> _cacheHistory = []; // Tracks cached order for LRU cleanup
  static const int _maxCachedTracks = 5;

  /// Returns the cached local file path for [trackId] if it exists on disk.
  String? getCachedPath(String trackId) {
    final path = _cachedPaths[trackId];
    if (path != null && File(path).existsSync()) {
      return path;
    }
    return null;
  }

  /// Silently pre-downloads the given track's audio to temporary cache directory in the background.
  Future<String?> precacheTrack(TrackEntity track) async {
    // 1. If track is already downloaded offline permanently, skip pre-cache
    if (track.localFilePath != null && File(track.localFilePath!).existsSync()) {
      return track.localFilePath;
    }

    // 2. If track is already pre-cached on disk, return cached path immediately
    final existing = getCachedPath(track.id);
    if (existing != null) {
      return existing;
    }

    // 3. Avoid duplicate simultaneous downloads for the same track
    if (_inProgressTrackIds.contains(track.id)) {
      return null;
    }

    final rawUrl = track.fileUrl;
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return null;
    }

    _inProgressTrackIds.add(track.id);

    try {
      final resolvedUrl = AudioUrlResolver.resolve(rawUrl.trim());
      final tempDir = await getTemporaryDirectory();
      final targetDir = Directory('${tempDir.path}/precache_tracks');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final targetPath = '${targetDir.path}/${track.id}.mp3';
      final tempDownloadPath = '$targetPath.part';

      // Clean up incomplete previous temporary file if present
      final tempFile = File(tempDownloadPath);
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }

      debugPrint('[AudioPrecacheService] Pre-downloading next track in background: ${track.title}');

      await _dio.download(
        resolvedUrl,
        tempDownloadPath,
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
          responseType: ResponseType.bytes,
        ),
      );

      final completedTemp = File(tempDownloadPath);
      if (await completedTemp.exists() && await completedTemp.length() > 0) {
        await completedTemp.rename(targetPath);
        _cachedPaths[track.id] = targetPath;
        _cacheHistory.add(track.id);

        debugPrint(
          '[AudioPrecacheService] Successfully pre-cached: ${track.title} -> $targetPath',
        );

        _trimCacheIfNeeded();
        return targetPath;
      }
      return null;
    } catch (e) {
      debugPrint('[AudioPrecacheService] Pre-caching ignored on error: $e');
      return null;
    } finally {
      _inProgressTrackIds.remove(track.id);
    }
  }

  /// Keeps the cache size constrained to avoid consuming unnecessary device storage
  void _trimCacheIfNeeded() {
    while (_cacheHistory.length > _maxCachedTracks) {
      final oldestTrackId = _cacheHistory.removeAt(0);
      final oldPath = _cachedPaths.remove(oldestTrackId);
      if (oldPath != null) {
        try {
          final file = File(oldPath);
          if (file.existsSync()) {
            file.deleteSync();
            debugPrint('[AudioPrecacheService] Trimmed old cached track: $oldestTrackId');
          }
        } catch (_) {}
      }
    }
  }

  /// Clears all temporary pre-cached tracks
  Future<void> clearCache() async {
    _cachedPaths.clear();
    _cacheHistory.clear();
    try {
      final tempDir = await getTemporaryDirectory();
      final targetDir = Directory('${tempDir.path}/precache_tracks');
      if (await targetDir.exists()) {
        await targetDir.delete(recursive: true);
      }
    } catch (_) {}
  }
}

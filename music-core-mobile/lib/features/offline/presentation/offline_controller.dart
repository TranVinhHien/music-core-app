import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/dependencies.dart';
import '../../catalog/domain/entities/track_entity.dart';
import '../../library/domain/entities/playlist_entity.dart';

part 'offline_controller.g.dart';

/// State of active downloads: maps trackId to download percentage (0.0 - 1.0).
@Riverpod(keepAlive: true)
class DownloadProgressController extends _$DownloadProgressController {
  @override
  Map<String, double> build() => const {};

  void _setProgress(String trackId, double progress) {
    state = {...state, trackId: progress};
  }

  void _clearProgress(String trackId) {
    final next = Map<String, double>.from(state)..remove(trackId);
    state = next;
  }

  /// Downloads a single track for offline listening.
  Future<void> downloadTrack(TrackEntity track) async {
    if (state.containsKey(track.id)) return;
    _setProgress(track.id, 0.0);

    final repo = ref.read(offlineRepositoryProvider);
    try {
      await repo.downloadTrack(
        track,
        onProgress: (received, total) {
          if (total > 0) {
            _setProgress(track.id, received / total);
          }
        },
      );
    } finally {
      _clearProgress(track.id);
    }
  }

  /// Downloads all tracks in a playlist.
  Future<void> downloadAllInPlaylist(List<TrackEntity> tracks) async {
    for (final track in tracks) {
      if (!track.isDownloaded && !state.containsKey(track.id)) {
        await downloadTrack(track);
      }
    }
  }

  /// Removes a downloaded track from device storage and database.
  Future<void> removeDownloadedTrack(String trackId) async {
    final repo = ref.read(offlineRepositoryProvider);
    await repo.removeDownloadedTrack(trackId);
  }
}

/// Real-time stream of all tracks saved locally on the device.
@riverpod
Stream<List<TrackEntity>> offlineTracksStream(Ref ref) {
  return ref.watch(offlineRepositoryProvider).watchDownloadedTracks();
}

/// Real-time stream of offline cached playlists.
@riverpod
Stream<List<PlaylistEntity>> offlinePlaylistsStream(Ref ref) {
  return ref.watch(offlineRepositoryProvider).watchOfflinePlaylists();
}

/// Real-time stream of offline cached favorites.
@riverpod
Stream<List<TrackEntity>> offlineFavoritesStream(Ref ref) {
  return ref.watch(offlineRepositoryProvider).watchOfflineFavorites();
}

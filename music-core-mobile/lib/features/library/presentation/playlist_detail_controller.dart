import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/dependencies.dart';
import '../../../core/result.dart';
import '../../catalog/domain/entities/track_entity.dart';
import '../domain/entities/playlist_entity.dart';
import 'playlists_controller.dart';

part 'playlist_detail_controller.g.dart';

@riverpod
class PlaylistDetailController extends _$PlaylistDetailController {
  @override
  Future<PlaylistEntity> build(String playlistId) async {
    final repository = ref.watch(libraryRepositoryProvider);
    final result = await repository.getPlaylistDetails(playlistId);

    switch (result) {
      case ResultOk(value: final playlist):
        try {
          final offlineRepo = ref.read(offlineRepositoryProvider);
          unawaited(offlineRepo.cachePlaylists([playlist]));
          unawaited(offlineRepo.cachePlaylistTracks(playlistId, playlist.tracks));
        } catch (_) {}
        return playlist;
      case ResultError(failure: final failure):
        try {
          final offlineRepo = ref.read(offlineRepositoryProvider);
          final localPlaylists = await offlineRepo.watchOfflinePlaylists().first;
          final matched = localPlaylists.where((p) => p.id == playlistId).firstOrNull;
          if (matched != null) {
            final tracks = await offlineRepo.getTracksForPlaylist(playlistId);
            return PlaylistEntity(
              id: matched.id,
              userId: matched.userId,
              name: matched.name,
              description: matched.description,
              coverImageUrl: matched.coverImageUrl,
              visibility: matched.visibility,
              trackCount: tracks.length,
              tracks: tracks,
              createdAt: matched.createdAt,
              updatedAt: matched.updatedAt,
            );
          }
        } catch (_) {}
        throw failure;
    }
  }

  Future<bool> removeTrack(String trackId) async {
    final repository = ref.read(libraryRepositoryProvider);
    final current = state.value;
    if (current == null) return false;

    // Optimistic UI update
    final updatedTracks = current.tracks.where((TrackEntity t) => t.id != trackId).toList();
    state = AsyncData(PlaylistEntity(
      id: current.id,
      userId: current.userId,
      name: current.name,
      description: current.description,
      coverImageUrl: current.coverImageUrl,
      visibility: current.visibility,
      trackCount: updatedTracks.length,
      tracks: updatedTracks,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
    ));

    final result = await repository.removeTrackFromPlaylist(playlistId, trackId);
    if (result is ResultError) {
      state = AsyncData(current);
      return false;
    }
    ref.invalidate(playlistsControllerProvider);
    return true;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

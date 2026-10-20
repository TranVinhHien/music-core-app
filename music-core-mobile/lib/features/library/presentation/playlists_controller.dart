import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/dependencies.dart';
import '../../../core/result.dart';
import '../domain/entities/playlist_entity.dart';

part 'playlists_controller.g.dart';

@Riverpod(keepAlive: true)
class PlaylistsController extends _$PlaylistsController {
  @override
  Future<List<PlaylistEntity>> build() async {
    final repository = ref.watch(libraryRepositoryProvider);
    final result = await repository.getPlaylists(limit: 50);

    switch (result) {
      case ResultOk(value: final playlists):
        try {
          final offlineRepo = ref.read(offlineRepositoryProvider);
          unawaited(offlineRepo.cachePlaylists(playlists));
        } catch (_) {}
        return playlists;
      case ResultError(failure: final failure):
        try {
          final offlineRepo = ref.read(offlineRepositoryProvider);
          final localPlaylists = await offlineRepo.watchOfflinePlaylists().first;
          if (localPlaylists.isNotEmpty) {
            return localPlaylists;
          }
        } catch (_) {}
        throw failure;
    }
  }

  Future<PlaylistEntity?> createPlaylist({
    required String name,
    String? description,
    String? coverImageUrl,
  }) async {
    final repository = ref.read(libraryRepositoryProvider);
    final result = await repository.createPlaylist(
      name: name,
      description: description,
      coverImageUrl: coverImageUrl,
    );

    switch (result) {
      case ResultOk(value: final playlist):
        state = AsyncData([playlist, ...?state.value]);
        try {
          final offlineRepo = ref.read(offlineRepositoryProvider);
          unawaited(offlineRepo.cachePlaylists([playlist]));
        } catch (_) {}
        return playlist;
      case ResultError():
        return null;
    }
  }

  Future<bool> deletePlaylist(String playlistId) async {
    final repository = ref.read(libraryRepositoryProvider);
    final result = await repository.deletePlaylist(playlistId);

    switch (result) {
      case ResultOk():
        state = AsyncData(
          (state.value ?? []).where((PlaylistEntity p) => p.id != playlistId).toList(),
        );
        return true;
      case ResultError():
        return false;
    }
  }

  Future<bool> addTrackToPlaylist(String playlistId, String trackId) async {
    final repository = ref.read(libraryRepositoryProvider);
    final result = await repository.addTrackToPlaylist(playlistId, trackId);
    if (result is ResultOk) {
      ref.invalidateSelf();
      return true;
    }
    return false;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

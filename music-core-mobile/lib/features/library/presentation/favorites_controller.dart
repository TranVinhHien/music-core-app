import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/dependencies.dart';
import '../../../core/result.dart';
import '../../catalog/domain/entities/track_entity.dart';

part 'favorites_controller.g.dart';

@Riverpod(keepAlive: true)
class FavoritesController extends _$FavoritesController {
  @override
  Future<List<TrackEntity>> build() async {
    final repository = ref.watch(libraryRepositoryProvider);
    final result = await repository.getFavoriteTracks(limit: 100);

    switch (result) {
      case ResultOk(value: final tracks):
        try {
          final offlineRepo = ref.read(offlineRepositoryProvider);
          unawaited(offlineRepo.cacheFavorites(tracks));
        } catch (_) {}
        return tracks;
      case ResultError(failure: final failure):
        try {
          final offlineRepo = ref.read(offlineRepositoryProvider);
          final localFavorites = await offlineRepo.watchOfflineFavorites().first;
          if (localFavorites.isNotEmpty) {
            return localFavorites;
          }
        } catch (_) {}
        throw failure;
    }
  }

  bool isFavorite(String trackId) {
    final currentTracks = state.value ?? [];
    return currentTracks.any((TrackEntity t) => t.id == trackId);
  }

  Future<bool> toggleFavorite(TrackEntity track) async {
    final currentList = state.value ?? [];
    final alreadyFavorite = currentList.any((TrackEntity t) => t.id == track.id);
    final repository = ref.read(libraryRepositoryProvider);

    // Optimistic UI update
    if (alreadyFavorite) {
      state = AsyncData(currentList.where((TrackEntity t) => t.id != track.id).toList());
      final result = await repository.removeFavorite(track.id);
      if (result is ResultError) {
        state = AsyncData(currentList);
        return false;
      }
      return true;
    } else {
      state = AsyncData([track, ...currentList]);
      final result = await repository.addFavorite(track.id);
      if (result is ResultError) {
        state = AsyncData(currentList);
        return false;
      }
      return true;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

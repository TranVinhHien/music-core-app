import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/dependencies.dart';
import '../../../core/result.dart';
import '../../catalog/domain/entities/track_entity.dart';

part 'songs_controller.g.dart';

@riverpod
class SongsQuery extends _$SongsQuery {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

@riverpod
class SongsController extends _$SongsController {
  Timer? _debounce;

  @override
  Future<List<TrackEntity>> build() async {
    final query = ref.watch(songsQueryProvider);
    final repository = ref.watch(catalogRepositoryProvider);

    final result = await repository.getTracks(
      query: query.isEmpty ? null : query,
      limit: 50,
    );

    switch (result) {
      case ResultOk(value: final tracks):
        if (query.trim().isNotEmpty) {
          ref.read(eventTrackerProvider).searchPerformed(
                query: query.trim(),
                resultsCount: tracks.length,
              );
        }
        try {
          final offlineRepo = ref.read(offlineRepositoryProvider);
          unawaited(offlineRepo.cacheCatalogTracks(tracks));
        } catch (_) {}
        return tracks;
      case ResultError(failure: final failure):
        if (query.trim().isNotEmpty) {
          ref.read(eventTrackerProvider).searchPerformed(
                query: query.trim(),
                resultsCount: 0,
              );
        }
        try {
          final offlineRepo = ref.read(offlineRepositoryProvider);
          final downloaded = await offlineRepo.getDownloadedTracks();
          if (downloaded.isNotEmpty) {
            return downloaded;
          }
        } catch (_) {}
        throw failure;
    }
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(songsQueryProvider.notifier).setQuery(query);
    });
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

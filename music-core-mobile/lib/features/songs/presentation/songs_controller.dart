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
  static const int pageSize = 10;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<TrackEntity>> build() async {
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;

    final query = ref.watch(songsQueryProvider);
    final repository = ref.watch(catalogRepositoryProvider);

    final result = await repository.getTracks(
      query: query.isEmpty ? null : query,
      page: 1,
      limit: pageSize,
    );

    switch (result) {
      case ResultOk(value: final tracks):
        if (query.trim().isNotEmpty) {
          ref.read(eventTrackerProvider).searchPerformed(
                query: query.trim(),
                resultsCount: tracks.length,
              );
        }
        _hasMore = tracks.length >= pageSize;
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
            _hasMore = false;
            return downloaded;
          }
        } catch (_) {}
        throw failure;
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final currentList = state.value;
    if (currentList == null) return;

    _isLoadingMore = true;
    final nextPage = _currentPage + 1;
    final query = ref.read(songsQueryProvider);
    final repository = ref.read(catalogRepositoryProvider);

    try {
      final result = await repository.getTracks(
        query: query.isEmpty ? null : query,
        page: nextPage,
        limit: pageSize,
      );

      switch (result) {
        case ResultOk(value: final newTracks):
          _currentPage = nextPage;
          if (newTracks.length < pageSize) {
            _hasMore = false;
          }
          final combined = [...currentList, ...newTracks];
          state = AsyncData(combined);
          try {
            final offlineRepo = ref.read(offlineRepositoryProvider);
            unawaited(offlineRepo.cacheCatalogTracks(newTracks));
          } catch (_) {}
        case ResultError():
          _hasMore = false;
      }
    } catch (_) {
      _hasMore = false;
    } finally {
      _isLoadingMore = false;
    }
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(songsQueryProvider.notifier).setQuery(query);
    });
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    ref.invalidateSelf();
    await future;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/dependencies.dart';
import '../../../core/result.dart';
import '../domain/entities/album_entity.dart';
import '../domain/entities/artist_entity.dart';
import '../domain/entities/catalog_search_result.dart';

/// Controls the current search query keyword.
class CatalogSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final catalogSearchQueryProvider =
    NotifierProvider<CatalogSearchQueryNotifier, String>(
  CatalogSearchQueryNotifier.new,
);

/// Controls the current target filter: 'all', 'tracks', 'albums', 'artists'.
class CatalogSearchFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String filter) => state = filter;
}

final catalogSearchFilterProvider =
    NotifierProvider<CatalogSearchFilterNotifier, String>(
  CatalogSearchFilterNotifier.new,
);

/// Unified search provider calling the backend 3-query full-text / trigram search.
final catalogSearchProvider =
    FutureProvider.autoDispose<CatalogSearchResult>((ref) async {
  final query = ref.watch(catalogSearchQueryProvider).trim();
  if (query.isEmpty) {
    return const CatalogSearchResult();
  }

  final type = ref.watch(catalogSearchFilterProvider);
  final repository = ref.watch(catalogRepositoryProvider);

  final result = await repository.searchCatalog(
    query: query,
    type: type,
    limit: 15,
  );

  switch (result) {
    case ResultOk(value: final searchResult):
      // Track analytics event
      ref.read(eventTrackerProvider).searchPerformed(
            query: query,
            resultsCount: searchResult.totalFound,
          );
      return searchResult;
    case ResultError(failure: final failure):
      ref.read(eventTrackerProvider).searchPerformed(
            query: query,
            resultsCount: 0,
          );
      throw failure;
  }
});

/// Fetches album details including full track list and artists.
final albumDetailProvider =
    FutureProvider.autoDispose.family<AlbumEntity, String>((ref, albumId) async {
  final repository = ref.watch(catalogRepositoryProvider);
  final result = await repository.getAlbumById(albumId);

  return switch (result) {
    ResultOk(value: final album) => album,
    ResultError(failure: final failure) => throw failure,
  };
});

/// Fetches artist details including discography and popular tracks.
final artistDetailProvider =
    FutureProvider.autoDispose.family<ArtistEntity, String>((ref, artistId) async {
  final repository = ref.watch(catalogRepositoryProvider);
  final result = await repository.getArtistById(artistId);

  return switch (result) {
    ResultOk(value: final artist) => artist,
    ResultError(failure: final failure) => throw failure,
  };
});


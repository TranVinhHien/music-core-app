import 'package:meta/meta.dart';
import 'album_entity.dart';
import 'artist_entity.dart';
import 'track_entity.dart';

/// Represents a paginated or grouped section of search results.
@immutable
class SearchResultSection<T> {
  const SearchResultSection({
    this.items = const [],
    this.total = 0,
  });

  final List<T> items;
  final int total;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

/// Represents the unified 3-part catalog search result across tracks, albums, and artists.
@immutable
class CatalogSearchResult {
  const CatalogSearchResult({
    this.tracks = const SearchResultSection<TrackEntity>(),
    this.albums = const SearchResultSection<AlbumEntity>(),
    this.artists = const SearchResultSection<ArtistEntity>(),
  });

  final SearchResultSection<TrackEntity> tracks;
  final SearchResultSection<AlbumEntity> albums;
  final SearchResultSection<ArtistEntity> artists;

  bool get isEmpty =>
      tracks.items.isEmpty && albums.items.isEmpty && artists.items.isEmpty;

  bool get isNotEmpty => !isEmpty;

  int get totalFound => tracks.total + albums.total + artists.total;

  factory CatalogSearchResult.fromJson(Map<String, dynamic> json) {
    // Parse Tracks section
    final tracksJson = json['tracks'];
    SearchResultSection<TrackEntity> tracksSection =
        const SearchResultSection<TrackEntity>();
    if (tracksJson is Map<String, dynamic>) {
      final itemsList = <TrackEntity>[];
      final items = tracksJson['items'] ?? tracksJson['data'];
      if (items is List) {
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            itemsList.add(TrackEntity.fromJson(item));
          }
        }
      }
      final total = tracksJson['total'] as int? ?? itemsList.length;
      tracksSection = SearchResultSection<TrackEntity>(
        items: itemsList,
        total: total,
      );
    }

    // Parse Albums section
    final albumsJson = json['albums'];
    SearchResultSection<AlbumEntity> albumsSection =
        const SearchResultSection<AlbumEntity>();
    if (albumsJson is Map<String, dynamic>) {
      final itemsList = <AlbumEntity>[];
      final items = albumsJson['items'] ?? albumsJson['data'];
      if (items is List) {
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            itemsList.add(AlbumEntity.fromJson(item));
          }
        }
      }
      final total = albumsJson['total'] as int? ?? itemsList.length;
      albumsSection = SearchResultSection<AlbumEntity>(
        items: itemsList,
        total: total,
      );
    }

    // Parse Artists section
    final artistsJson = json['artists'];
    SearchResultSection<ArtistEntity> artistsSection =
        const SearchResultSection<ArtistEntity>();
    if (artistsJson is Map<String, dynamic>) {
      final itemsList = <ArtistEntity>[];
      final items = artistsJson['items'] ?? artistsJson['data'];
      if (items is List) {
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            itemsList.add(ArtistEntity.fromJson(item));
          }
        }
      }
      final total = artistsJson['total'] as int? ?? itemsList.length;
      artistsSection = SearchResultSection<ArtistEntity>(
        items: itemsList,
        total: total,
      );
    }

    return CatalogSearchResult(
      tracks: tracksSection,
      albums: albumsSection,
      artists: artistsSection,
    );
  }
}


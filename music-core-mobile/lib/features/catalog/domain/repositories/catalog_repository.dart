import '../../../../core/result.dart';
import '../entities/album_entity.dart';
import '../entities/artist_entity.dart';
import '../entities/catalog_search_result.dart';
import '../entities/track_entity.dart';

abstract interface class CatalogRepository {
  /// Fetches paginated tracks from Catalog API, with optional search query.
  Future<Result<List<TrackEntity>>> getTracks({
    String? query,
    int page = 1,
    int limit = 20,
  });

  /// Fetches a single track details by ID.
  Future<Result<TrackEntity>> getTrackById(String id);

  /// Performs full-text, fuzzy & trigram search across tracks, albums, and artists.
  Future<Result<CatalogSearchResult>> searchCatalog({
    required String query,
    int page = 1,
    int limit = 10,
    String type = 'all',
  });

  /// Fetches full album details including tracks and artists.
  Future<Result<AlbumEntity>> getAlbumById(String id);

  /// Fetches full artist details including albums and top tracks.
  Future<Result<ArtistEntity>> getArtistById(String id);

  /// Fetches a truly random track from the catalog, optionally excluding current or recent track IDs.
  Future<Result<TrackEntity>> getRandomTrack({
    String? excludeTrackId,
    List<String>? excludeTrackIds,
    String? genreId,
  });
}

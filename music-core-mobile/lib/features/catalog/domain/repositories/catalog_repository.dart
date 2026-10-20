import '../../../../core/result.dart';
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
}

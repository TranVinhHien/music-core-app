import 'package:meta/meta.dart';
import '../../../catalog/domain/entities/track_entity.dart';

/// Represents a playlist in the user's library.
@immutable
class PlaylistEntity {
  const PlaylistEntity({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.visibility = 'PRIVATE',
    this.trackCount = 0,
    this.tracks = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final String visibility;
  final int trackCount;
  final List<TrackEntity> tracks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PlaylistEntity.fromJson(Map<String, dynamic> json) {
    // Parse nested tracks if present
    final tracksList = <TrackEntity>[];
    final rawTracks = json['tracks'] ?? json['playlistTracks'];
    if (rawTracks is List) {
      for (final item in rawTracks) {
        if (item is Map<String, dynamic>) {
          // May be directly a track or wrapped in { playlistId, trackId, track: { ... } }
          if (item['track'] is Map<String, dynamic>) {
            tracksList.add(TrackEntity.fromJson(item['track'] as Map<String, dynamic>));
          } else {
            tracksList.add(TrackEntity.fromJson(item));
          }
        }
      }
    }

    final count = json['trackCount'] as int? ??
        json['track_count'] as int? ??
        json['_count']?['tracks'] as int? ??
        json['_count']?['playlistTracks'] as int? ??
        tracksList.length;

    return PlaylistEntity(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Playlist',
      description: json['description'] as String?,
      coverImageUrl: json['coverImageUrl'] as String? ?? json['cover_image_url'] as String?,
      visibility: json['visibility'] as String? ?? 'PRIVATE',
      trackCount: count,
      tracks: tracksList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'description': description,
        'cover_image_url': coverImageUrl,
        'visibility': visibility,
        'track_count': trackCount,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

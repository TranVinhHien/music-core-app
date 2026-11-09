import 'package:meta/meta.dart';
import 'album_entity.dart';
import 'track_entity.dart';

/// Represents an artist in the music catalog.
@immutable
class ArtistEntity {
  const ArtistEntity({
    required this.id,
    required this.name,
    this.imageUrl,
    this.bio,
    this.tracks = const [],
    this.albums = const [],
  });

  final String id;
  final String name;
  final String? imageUrl;
  final String? bio;
  final List<TrackEntity> tracks;
  final List<AlbumEntity> albums;

  ArtistEntity copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? bio,
    List<TrackEntity>? tracks,
    List<AlbumEntity>? albums,
  }) {
    return ArtistEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      tracks: tracks ?? this.tracks,
      albums: albums ?? this.albums,
    );
  }

  factory ArtistEntity.fromJson(Map<String, dynamic> json) {
    // Parse albums from albumArtists if present
    final albumsList = <AlbumEntity>[];
    final albumArtists = json['albumArtists'] as List?;
    if (albumArtists != null) {
      for (final item in albumArtists) {
        if (item is Map<String, dynamic> && item['album'] is Map<String, dynamic>) {
          albumsList.add(AlbumEntity.fromJson(item['album'] as Map<String, dynamic>));
        }
      }
    }

    // Parse tracks from trackArtists if present
    final tracksList = <TrackEntity>[];
    final trackArtists = json['trackArtists'] as List?;
    if (trackArtists != null) {
      for (final item in trackArtists) {
        if (item is Map<String, dynamic> && item['track'] is Map<String, dynamic>) {
          final trackJson = Map<String, dynamic>.from(item['track'] as Map<String, dynamic>);
          // Ensure artistName is populated from parent if not present
          trackJson['artistName'] ??= json['name'];
          tracksList.add(TrackEntity.fromJson(trackJson));
        }
      }
    }

    return ArtistEntity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Nghệ sĩ chưa rõ',
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      bio: json['bio'] as String?,
      tracks: tracksList,
      albums: albumsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image_url': imageUrl,
        'bio': bio,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtistEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}


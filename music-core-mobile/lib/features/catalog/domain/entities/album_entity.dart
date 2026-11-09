import 'package:meta/meta.dart';
import 'track_entity.dart';

/// Represents an album in the music catalog.
@immutable
class AlbumEntity {
  const AlbumEntity({
    required this.id,
    required this.title,
    this.coverImageUrl,
    this.releaseDate,
    this.artistName = 'Nghệ sĩ chưa rõ',
    this.artistId,
    this.totalTracks = 0,
    this.tracks = const [],
  });

  final String id;
  final String title;
  final String? coverImageUrl;
  final DateTime? releaseDate;
  final String artistName;
  final String? artistId;
  final int totalTracks;
  final List<TrackEntity> tracks;

  AlbumEntity copyWith({
    String? id,
    String? title,
    String? coverImageUrl,
    DateTime? releaseDate,
    String? artistName,
    String? artistId,
    int? totalTracks,
    List<TrackEntity>? tracks,
  }) {
    return AlbumEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      releaseDate: releaseDate ?? this.releaseDate,
      artistName: artistName ?? this.artistName,
      artistId: artistId ?? this.artistId,
      totalTracks: totalTracks ?? this.totalTracks,
      tracks: tracks ?? this.tracks,
    );
  }

  String get formattedReleaseYear {
    if (releaseDate == null) return '';
    return releaseDate!.year.toString();
  }

  factory AlbumEntity.fromJson(Map<String, dynamic> json) {
    // Determine artist name and artistId from artists array or albumArtists array
    String artistName = 'Nghệ sĩ chưa rõ';
    String? artistId;

    final artists = json['artists'] as List?;
    if (artists != null && artists.isNotEmpty) {
      final names = artists
          .map((a) => (a is Map<String, dynamic> ? a['name'] as String? : null) ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      if (names.isNotEmpty) {
        artistName = names.join(', ');
      }
      final first = artists[0] as Map<String, dynamic>?;
      artistId = first?['id'] as String?;
    }

    final albumArtists = json['albumArtists'] as List?;
    if (albumArtists != null && albumArtists.isNotEmpty) {
      final names = <String>[];
      for (final item in albumArtists) {
        if (item is Map<String, dynamic>) {
          final art = item['artist'] as Map<String, dynamic>?;
          if (art != null && art['name'] is String) {
            names.add(art['name'] as String);
            artistId ??= art['id'] as String?;
          }
        }
      }
      if (names.isNotEmpty) {
        artistName = names.join(', ');
      }
    }

    DateTime? releaseDate;
    final rawDate = json['releaseDate'] ?? json['release_date'];
    if (rawDate != null) {
      releaseDate = DateTime.tryParse(rawDate.toString());
    }

    // Parse tracks list if present
    final tracksList = <TrackEntity>[];
    final rawTracks = json['tracks'] as List?;
    if (rawTracks != null) {
      for (final t in rawTracks) {
        if (t is Map<String, dynamic>) {
          tracksList.add(TrackEntity.fromJson(t));
        }
      }
    }

    final totalTracks = json['totalTracks'] as int? ??
        json['total_tracks'] as int? ??
        tracksList.length;

    return AlbumEntity(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Chưa có tiêu đề',
      coverImageUrl: json['coverImageUrl'] as String? ?? json['cover_image_url'] as String?,
      releaseDate: releaseDate,
      artistName: artistName,
      artistId: artistId,
      totalTracks: totalTracks,
      tracks: tracksList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'cover_image_url': coverImageUrl,
        'release_date': releaseDate?.toIso8601String(),
        'artist_name': artistName,
        'artist_id': artistId,
        'total_tracks': totalTracks,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}


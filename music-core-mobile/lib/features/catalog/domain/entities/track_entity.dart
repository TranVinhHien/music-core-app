import 'package:meta/meta.dart';

/// Represents a song/track entity from the music catalog.
@immutable
class TrackEntity {
  const TrackEntity({
    required this.id,
    required this.title,
    this.durationMs,
    this.fileUrl,
    required this.artistName,
    this.albumTitle,
    this.coverImageUrl,
    this.localFilePath,
    this.fileSizeBytes,
    this.isDownloaded = false,
    this.cueInMs,
    this.cueOutMs,
  });

  final String id;
  final String title;
  final int? durationMs;
  final String? fileUrl;
  final String artistName;
  final String? albumTitle;
  final String? coverImageUrl;
  final String? localFilePath;
  final int? fileSizeBytes;
  final bool isDownloaded;
  final int? cueInMs;
  final int? cueOutMs;

  TrackEntity copyWith({
    String? id,
    String? title,
    int? durationMs,
    String? fileUrl,
    String? artistName,
    String? albumTitle,
    String? coverImageUrl,
    String? localFilePath,
    int? fileSizeBytes,
    bool? isDownloaded,
    int? cueInMs,
    int? cueOutMs,
  }) {
    return TrackEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMs: durationMs ?? this.durationMs,
      fileUrl: fileUrl ?? this.fileUrl,
      artistName: artistName ?? this.artistName,
      albumTitle: albumTitle ?? this.albumTitle,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      cueInMs: cueInMs ?? this.cueInMs,
      cueOutMs: cueOutMs ?? this.cueOutMs,
    );
  }

  /// Formatted file size string, e.g. "3.4 MB"
  String get formattedFileSize {
    if (fileSizeBytes == null || fileSizeBytes! <= 0) return '';
    final mb = fileSizeBytes! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Formatted duration string, e.g. "03:45"
  String get formattedDuration {
    if (durationMs == null || durationMs! <= 0) return '--:--';
    final totalSeconds = durationMs! ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory TrackEntity.fromJson(Map<String, dynamic> json) {
    // Determine artist name from trackArtists array or artist field
    String artistName = 'Nghệ sĩ chưa rõ';
    final trackArtists = json['trackArtists'] as List?;
    if (trackArtists != null && trackArtists.isNotEmpty) {
      final first = trackArtists[0] as Map<String, dynamic>?;
      final artistObj = first?['artist'] as Map<String, dynamic>?;
      if (artistObj != null && artistObj['name'] != null) {
        artistName = artistObj['name'] as String;
      }
    } else if (json['artist'] is Map<String, dynamic>) {
      artistName = (json['artist']['name'] as String?) ?? artistName;
    } else if (json['artistName'] is String) {
      artistName = json['artistName'] as String;
    }

    // Determine cover image and album title
    String? coverImageUrl;
    String? albumTitle;
    final album = json['album'] as Map<String, dynamic>?;
    if (album != null) {
      albumTitle = album['title'] as String?;
      coverImageUrl = album['coverImageUrl'] as String? ?? album['cover_image_url'] as String?;
    }
    coverImageUrl ??= json['coverImageUrl'] as String? ?? json['cover_image_url'] as String?;

    final audioAnalysis = json['audioAnalysis'] as Map<String, dynamic>?;
    final cueInMs = audioAnalysis?['cueInMs'] as int? ??
        audioAnalysis?['cue_in_ms'] as int? ??
        audioAnalysis?['firstDownbeatMs'] as int? ??
        audioAnalysis?['first_downbeat_ms'] as int? ??
        json['cueInMs'] as int? ??
        json['cue_in_ms'] as int?;
    final cueOutMs = audioAnalysis?['cueOutMs'] as int? ??
        audioAnalysis?['cue_out_ms'] as int? ??
        json['cueOutMs'] as int? ??
        json['cue_out_ms'] as int?;

    return TrackEntity(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Chưa có tiêu đề',
      durationMs: json['durationMs'] as int? ?? json['duration_ms'] as int?,
      fileUrl: json['fileUrl'] as String? ?? json['file_url'] as String?,
      artistName: artistName,
      albumTitle: albumTitle,
      coverImageUrl: coverImageUrl,
      cueInMs: cueInMs,
      cueOutMs: cueOutMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'duration_ms': durationMs,
        'file_url': fileUrl,
        'artist_name': artistName,
        'album_title': albumTitle,
        'cover_image_url': coverImageUrl,
        'cue_in_ms': cueInMs,
        'cue_out_ms': cueOutMs,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Helper to resolve audio file URLs to direct streaming endpoints.
abstract final class AudioUrlResolver {
  /// Converts viewer URLs (like Google Drive preview links) into direct audio streaming URLs.
  /// Standard URLs (S3, CDN, MP3/AAC streams) are returned unchanged.
  static String resolve(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;

    // Already a direct export=download link
    if (trimmed.contains('export=download')) {
      return trimmed;
    }

    // Pattern: https://drive.google.com/file/d/{FILE_ID}/view?usp=sharing
    final driveFileRegex = RegExp(r'drive\.google\.com/file/d/([a-zA-Z0-9_-]+)');
    final match = driveFileRegex.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }

    // Pattern: https://drive.google.com/open?id={FILE_ID} or uc?id={FILE_ID}
    if (trimmed.contains('drive.google.com') || trimmed.contains('docs.google.com')) {
      final driveIdRegex = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)');
      final idMatch = driveIdRegex.firstMatch(trimmed);
      if (idMatch != null && idMatch.groupCount >= 1) {
        final fileId = idMatch.group(1);
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    }

    return trimmed;
  }
}

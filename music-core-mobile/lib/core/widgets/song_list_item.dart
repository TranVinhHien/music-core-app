import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/catalog/domain/entities/track_entity.dart';
import '../../features/offline/presentation/offline_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class SongListItem extends ConsumerWidget {
  const SongListItem({
    super.key,
    required this.track,
    this.isFavorite = false,
    this.isDownloaded,
    this.downloadProgress,
    this.onTap,
    this.onFavoriteToggle,
    this.onAddToPlaylist,
    this.onDownloadToggle,
    this.trailing,
  });

  final TrackEntity track;
  final bool isFavorite;
  final bool? isDownloaded;
  final double? downloadProgress;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onDownloadToggle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDownloads = ref.watch(downloadProgressControllerProvider);
    final actualProgress = downloadProgress ?? activeDownloads[track.id];
    final downloadedTracks = ref.watch(offlineTracksStreamProvider).asData?.value ?? [];
    final actualIsDownloaded = isDownloaded ??
        (track.isDownloaded || downloadedTracks.any((TrackEntity t) => t.id == track.id));

    VoidCallback? downloadHandler = onDownloadToggle;
    if (downloadHandler == null) {
      if (actualIsDownloaded) {
        downloadHandler = () {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Quản lý bài hát offline'),
              content: Text(
                'Xoá bài hát "${track.title}" khỏi danh sách nghe offline để giải phóng dung lượng?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Huỷ'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ref
                        .read(downloadProgressControllerProvider.notifier)
                        .removeDownloadedTrack(track.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã xoá file offline: ${track.title}')),
                    );
                  },
                  child: const Text('Xoá file'),
                ),
              ],
            ),
          );
        };
      } else {
        downloadHandler = () {
          ref.read(downloadProgressControllerProvider.notifier).downloadTrack(track);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đang tải bài hát: ${track.title}'),
              duration: const Duration(seconds: 2),
            ),
          );
        };
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // Cover Artwork
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  width: 52,
                  height: 52,
                  color: AppColors.darkSurfaceElevated,
                  child: track.coverImageUrl != null && track.coverImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: track.coverImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: Icon(Icons.music_note, color: AppColors.darkTextMuted, size: 24),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(Icons.music_note, color: AppColors.darkTextMuted, size: 24),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.music_note, color: AppColors.darkTextMuted, size: 24),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Track Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            track.artistName,
                            style: AppTypography.secondaryText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (track.durationMs != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Text('•', style: AppTypography.secondaryText),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            track.formattedDuration,
                            style: AppTypography.secondaryText,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              if (trailing != null)
                trailing!
              else ...[
                // Download status / action
                if (actualProgress != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        value: actualProgress > 0 ? actualProgress : null,
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (actualIsDownloaded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: IconButton(
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      onPressed: downloadHandler,
                      tooltip: 'Đã tải xuống (nhấn để quản lý)',
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.download_rounded, size: 20),
                    color: AppColors.darkTextMuted,
                    onPressed: downloadHandler,
                    tooltip: 'Tải bài hát này về máy',
                  ),
                if (onFavoriteToggle != null)
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      color: isFavorite ? AppColors.error : AppColors.darkTextMuted,
                      size: 22,
                    ),
                    onPressed: onFavoriteToggle,
                    tooltip: isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
                  ),
                if (onAddToPlaylist != null)
                  IconButton(
                    icon: const Icon(Icons.playlist_add_rounded, size: 22),
                    color: AppColors.darkTextMuted,
                    onPressed: onAddToPlaylist,
                    tooltip: 'Thêm vào playlist',
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

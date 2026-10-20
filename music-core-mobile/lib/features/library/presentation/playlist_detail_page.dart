import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/song_list_item.dart';
import '../../catalog/domain/entities/track_entity.dart';
import '../../offline/presentation/offline_controller.dart';
import '../../player/presentation/now_playing_page.dart';
import '../../player/presentation/player_controller.dart';
import 'favorites_controller.dart';
import 'playlist_detail_controller.dart';
import 'playlists_controller.dart';

class PlaylistDetailPage extends ConsumerWidget {
  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
  });

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(playlistDetailControllerProvider(playlistId));
    final favoritesAsync = ref.watch(favoritesControllerProvider);
    final favoriteIds =
        favoritesAsync.value?.map((TrackEntity t) => t.id).toSet() ??
            <String>{};

    final offlineTracksAsync = ref.watch(offlineTracksStreamProvider);
    final downloadedIds =
        offlineTracksAsync.value?.map((TrackEntity t) => t.id).toSet() ??
            <String>{};
    final activeDownloads = ref.watch(downloadProgressControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tải lại',
            onPressed: () =>
                ref.read(playlistDetailControllerProvider(playlistId).notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            tooltip: 'Xóa playlist',
            onPressed: () => _confirmDelete(context, ref, detailAsync.value?.name),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (playlist) {
          return CustomScrollView(
            slivers: [
              // Header Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.paddingScreen,
                  child: Column(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.darkSurfaceElevated,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.queue_music_rounded,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        playlist.name,
                        style: AppTypography.display.copyWith(fontSize: 24),
                        textAlign: TextAlign.center,
                      ),
                      if (playlist.description != null &&
                          playlist.description!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          playlist.description!,
                          style: AppTypography.secondaryText,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${playlist.tracks.length} bài hát',
                        style: AppTypography.caption.copyWith(color: AppColors.primary),
                      ),
                      if (playlist.tracks.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.darkSurfaceElevated,
                            foregroundColor: AppColors.primary,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.borderRadiusMd,
                              side: BorderSide(color: AppColors.darkBorder),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(
                            Icons.download_for_offline_rounded,
                            size: 20,
                          ),
                          label: const Text('Tải tất cả để nghe offline'),
                          onPressed: () {
                            ref
                                .read(downloadProgressControllerProvider.notifier)
                                .downloadAllInPlaylist(playlist.tracks);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đang tải ${playlist.tracks.length} bài hát trong playlist về máy...',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Track List
              if (playlist.tracks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView(
                    title: 'Chưa có bài hát trong playlist',
                    message: 'Chuyển sang tab Bài hát để thêm bài vào playlist này',
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = playlist.tracks[index];
                      final isFav = favoriteIds.contains(track.id);
                      final isDown = downloadedIds.contains(track.id);
                      final progress = activeDownloads[track.id];

                      return SongListItem(
                        track: track,
                        isFavorite: isFav,
                        isDownloaded: isDown,
                        downloadProgress: progress,
                        onDownloadToggle: isDown
                            ? null
                            : () {
                                ref
                                    .read(downloadProgressControllerProvider.notifier)
                                    .downloadTrack(track);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đang tải "${track.title}" về máy...'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                        onTap: () {
                          ref
                              .read(playerControllerProvider.notifier)
                              .playTrack(track, queue: playlist.tracks);
                          NowPlayingPage.show(context);
                        },
                        onFavoriteToggle: () {
                          ref
                              .read(favoritesControllerProvider.notifier)
                              .toggleFavorite(track);
                        },
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline_rounded,
                            color: AppColors.darkTextMuted,
                            size: 20,
                          ),
                          tooltip: 'Xóa khỏi playlist',
                          onPressed: () async {
                            final success = await ref
                                .read(playlistDetailControllerProvider(playlistId).notifier)
                                .removeTrack(track.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Đã xóa "${track.title}" khỏi playlist'
                                        : 'Không thể xóa bài hát',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                    childCount: playlist.tracks.length,
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(
          message: e.toString(),
          onRetry: () =>
              ref.read(playlistDetailControllerProvider(playlistId).notifier).refresh(),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String? playlistName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa playlist "${playlistName ?? 'này'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(playlistsControllerProvider.notifier)
          .deletePlaylist(playlistId);
      if (context.mounted) {
        if (success) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã xóa playlist "${playlistName ?? ''}"',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể xóa playlist. Vui lòng thử lại.'),
            ),
          );
        }
      }
    }
  }
}

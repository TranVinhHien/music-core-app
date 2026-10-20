import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/song_list_item.dart';
import '../../catalog/domain/entities/track_entity.dart';
import '../../player/presentation/now_playing_page.dart';
import '../../player/presentation/player_controller.dart';
import 'offline_controller.dart';

/// Dedicated screen for managing offline downloaded music and storage.
class OfflineMusicPage extends ConsumerWidget {
  const OfflineMusicPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineTracksAsync = ref.watch(offlineTracksStreamProvider);
    final activeDownloads = ref.watch(downloadProgressControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Nhạc Offline', style: AppTypography.screenTitle),
        centerTitle: true,
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
      ),
      body: offlineTracksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Lỗi tải danh sách offline: $err',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (tracks) {
          if (tracks.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSpacing.paddingScreenHorizontal,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: AppColors.darkSurfaceElevated,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        size: 44,
                        color: AppColors.darkTextMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Chưa có bài hát tải về',
                      style: AppTypography.sectionTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Bấm biểu tượng tải xuống trong Playlist hoặc danh sách bài hát để nghe nhạc mà không cần mạng Internet.',
                      style: AppTypography.secondaryText,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Calculate total bytes
          final totalBytes = tracks.fold<int>(
            0,
            (sum, t) => sum + (t.fileSizeBytes ?? 0),
          );
          final totalMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);

          return CustomScrollView(
            slivers: [
              // Header Summary & Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceElevated,
                      borderRadius: AppRadius.borderRadiusLg,
                      border: Border.all(
                        color: AppColors.darkBorder,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.offline_pin_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${tracks.length} bài hát đã tải',
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Dung lượng đã dùng: $totalMb MB',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.darkTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: AppRadius.borderRadiusMd,
                                  ),
                                ),
                                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                                label: const Text('Phát tất cả'),
                                onPressed: () {
                                  ref.read(playerControllerProvider.notifier).playTrack(
                                        tracks.first,
                                        queue: tracks,
                                      );
                                  NowPlayingPage.show(context);
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: AppColors.darkBorder),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: AppRadius.borderRadiusMd,
                                  ),
                                ),
                                icon: const Icon(Icons.shuffle_rounded, size: 20),
                                label: const Text('Trộn bài'),
                                onPressed: () {
                                  final shuffled = List<TrackEntity>.from(tracks)..shuffle();
                                  ref.read(playerControllerProvider.notifier).playTrack(
                                        shuffled.first,
                                        queue: shuffled,
                                      );
                                  NowPlayingPage.show(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Downloaded tracks list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = tracks[index];
                    final progress = activeDownloads[track.id];

                    return SongListItem(
                      track: track,
                      downloadProgress: progress,
                      isDownloaded: true,
                      onTap: () {
                        ref.read(playerControllerProvider.notifier).playTrack(
                              track,
                              queue: tracks,
                            );
                        NowPlayingPage.show(context);
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (track.fileSizeBytes != null && track.fileSizeBytes! > 0)
                            Text(
                              track.formattedFileSize,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.darkTextMuted,
                              ),
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.darkTextMuted,
                              size: 20,
                            ),
                            tooltip: 'Xóa khỏi máy',
                            onPressed: () => _confirmDelete(context, ref, track),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: tracks.length,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, TrackEntity track) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceElevated,
        title: const Text('Xoá file offline?'),
        content: Text(
          'Bạn có chắc chắn muốn xoá bài hát "${track.title}" khỏi bộ nhớ thiết bị để giải phóng dung lượng?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref
                  .read(downloadProgressControllerProvider.notifier)
                  .removeDownloadedTrack(track.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xoá bài hát "${track.title}" khỏi thiết bị'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }
}

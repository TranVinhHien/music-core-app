import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/error_state_view.dart';
import '../domain/entities/playlist_entity.dart';
import 'playlists_controller.dart';
import 'widgets/create_playlist_dialog.dart';

class PlaylistsPage extends ConsumerWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist Của Bạn', style: AppTypography.screenTitle),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.offline_pin_rounded,
              color: AppColors.primary,
              size: 26,
            ),
            tooltip: 'Nhạc Offline',
            onPressed: () => context.push('/offline'),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28),
            tooltip: 'Tạo playlist mới',
            onPressed: () => _showCreatePlaylist(context, ref),
          ),
        ],
      ),
      body: playlistsAsync.when(
        data: (playlists) {
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(playlistsControllerProvider.notifier).refresh(),
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              itemCount: playlists.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    color: AppColors.darkSurfaceElevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderRadiusLg,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: AppRadius.borderRadiusLg,
                      onTap: () => context.push('/offline'),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.offline_pin_rounded,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nhạc Đã Tải Về',
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Nghe nhạc offline không cần mạng Internet',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.darkTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppColors.darkTextMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final playlist = playlists[index - 1];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    borderRadius: AppRadius.borderRadiusMd,
                    onTap: () => context.go('/playlists/${playlist.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.darkSurfaceElevated,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Icon(
                              Icons.queue_music_rounded,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playlist.name,
                                  style: AppTypography.sectionTitle.copyWith(fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  '${playlist.trackCount} bài hát',
                                  style: AppTypography.secondaryText,
                                ),
                                if (playlist.description != null &&
                                    playlist.description!.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    playlist.description!,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.darkTextMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: AppColors.darkTextMuted),
                            onSelected: (value) {
                              if (value == 'delete') {
                                _confirmDeletePlaylist(context, ref, playlist);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                    SizedBox(width: 8),
                                    Text('Xóa playlist', style: TextStyle(color: AppColors.error)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(
          message: e.toString(),
          onRetry: () => ref.read(playlistsControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }

  Future<void> _confirmDeletePlaylist(
    BuildContext context,
    WidgetRef ref,
    PlaylistEntity playlist,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa playlist "${playlist.name}"?'),
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

    if (confirmed == true) {
      final success = await ref
          .read(playlistsControllerProvider.notifier)
          .deletePlaylist(playlist.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Đã xóa playlist "${playlist.name}"'
                  : 'Không thể xóa playlist',
            ),
          ),
        );
      }
    }
  }

  Future<void> _showCreatePlaylist(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const CreatePlaylistDialog(),
    );
    if (result != null) {
      final created = await ref.read(playlistsControllerProvider.notifier).createPlaylist(
            name: result['name']!,
            description: result['description'],
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              created != null
                  ? 'Đã tạo playlist "${created.name}"'
                  : 'Không thể tạo playlist. Vui lòng thử lại.',
            ),
          ),
        );
      }
    }
  }
}

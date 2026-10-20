import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../catalog/domain/entities/track_entity.dart';
import '../playlists_controller.dart';
import 'create_playlist_dialog.dart';

class AddToPlaylistSheet extends ConsumerWidget {
  const AddToPlaylistSheet({
    super.key,
    required this.track,
  });

  final TrackEntity track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsControllerProvider);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thêm vào Playlist', style: AppTypography.sectionTitle),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await showDialog<Map<String, String>>(
                        context: context,
                        builder: (_) => const CreatePlaylistDialog(),
                      );
                      if (result != null) {
                        final created = await ref
                            .read(playlistsControllerProvider.notifier)
                            .createPlaylist(
                              name: result['name']!,
                              description: result['description'],
                            );
                        if (created != null && context.mounted) {
                          final success = await ref
                              .read(playlistsControllerProvider.notifier)
                              .addTrackToPlaylist(created.id, track.id);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Đã thêm vào "${created.name}"'
                                      : 'Không thể thêm bài hát',
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tạo mới'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: playlistsAsync.when(
                data: (playlists) {
                  if (playlists.isEmpty) {
                    return const EmptyStateView(
                      title: 'Chưa có playlist',
                      message: 'Bấm "Tạo mới" ở trên để tạo playlist đầu tiên của bạn',
                    );
                  }
                  return ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      return ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.darkSurfaceElevated,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: const Icon(Icons.queue_music, color: AppColors.primary),
                        ),
                        title: Text(
                          playlist.name,
                          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${playlist.trackCount} bài hát',
                          style: AppTypography.secondaryText,
                        ),
                        onTap: () async {
                          final success = await ref
                              .read(playlistsControllerProvider.notifier)
                              .addTrackToPlaylist(playlist.id, track.id);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Đã thêm vào "${playlist.name}"'
                                      : 'Không thể thêm bài hát vào playlist',
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorStateView(
                  message: e.toString(),
                  onRetry: () => ref.read(playlistsControllerProvider.notifier).refresh(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

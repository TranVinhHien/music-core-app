import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/dependencies.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/song_list_item.dart';
import '../../catalog/domain/entities/track_entity.dart';
import '../../events/domain/entities/client_event.dart';
import '../../library/presentation/favorites_controller.dart';
import '../../library/presentation/widgets/add_to_playlist_sheet.dart';
import '../../player/presentation/now_playing_page.dart';
import '../../player/presentation/player_controller.dart';
import 'search_controller.dart';

class AlbumDetailPage extends ConsumerWidget {
  const AlbumDetailPage({
    super.key,
    required this.albumId,
  });

  final String albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumDetailProvider(albumId));
    final favoritesAsync = ref.watch(favoritesControllerProvider);
    final favoriteIds =
        favoritesAsync.value?.map((TrackEntity t) => t.id).toSet() ??
            <String>{};

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
            onPressed: () => ref.refresh(albumDetailProvider(albumId)),
          ),
        ],
      ),
      body: albumAsync.when(
        data: (album) {
          final tracks = album.tracks;

          return CustomScrollView(
            slivers: [
              // Header Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.paddingScreen,
                  child: Column(
                    children: [
                      // Album Cover Art
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: album.coverImageUrl != null &&
                                album.coverImageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: album.coverImageUrl!,
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 180,
                                  height: 180,
                                  color: AppColors.darkSurfaceElevated,
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 180,
                                  height: 180,
                                  color: AppColors.darkSurfaceElevated,
                                  child: const Icon(
                                    Icons.album_rounded,
                                    size: 64,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: AppColors.darkSurfaceElevated,
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: const Icon(
                                  Icons.album_rounded,
                                  size: 64,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        album.title,
                        style: AppTypography.display.copyWith(fontSize: 22),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: album.artistId != null
                            ? () => context.push('/artists/${album.artistId}')
                            : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              album.artistName,
                              style: AppTypography.bodyMedium.copyWith(
                                color: album.artistId != null
                                    ? AppColors.primary
                                    : AppColors.darkTextSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (album.artistId != null) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Album • ${album.formattedReleaseYear.isNotEmpty ? "${album.formattedReleaseYear} • " : ""}${tracks.length} bài hát',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Action Button: Play All
                      if (tracks.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, size: 26),
                            label: const Text(
                              'Phát tất cả',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              final firstTrack = tracks.first;
                              ref.read(playerControllerProvider.notifier).playTrack(
                                    firstTrack,
                                    queue: tracks,
                                    source: EventSourceModel(type: 'album', id: album.id),
                                  );
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const NowPlayingPage(),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Danh sách bài hát',
                    style: AppTypography.sectionTitle,
                  ),
                ),
              ),

              if (tracks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView(
                    title: 'Album chưa có bài hát',
                    message: 'Các bài hát thuộc album này sẽ xuất hiện ở đây.',
                    icon: Icons.music_off_rounded,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = tracks[index];
                      final isFav = favoriteIds.contains(track.id);

                      return SongListItem(
                        track: track,
                        isFavorite: isFav,
                        onTap: () {
                          ref.read(playerControllerProvider.notifier).playTrack(
                                track,
                                queue: tracks,
                                source: EventSourceModel(type: 'album', id: album.id),
                              );
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const NowPlayingPage(),
                          );
                        },
                        onFavoriteToggle: () {
                          ref
                              .read(favoritesControllerProvider.notifier)
                              .toggleFavorite(track);
                        },
                        onAddToPlaylist: () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => AddToPlaylistSheet(track: track),
                          );
                        },
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: ErrorStateView(
            message: 'Không thể tải chi tiết album: $error',
            onRetry: () => ref.refresh(albumDetailProvider(albumId)),
          ),
        ),
      ),
    );
  }
}


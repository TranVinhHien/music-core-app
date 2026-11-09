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

class ArtistDetailPage extends ConsumerWidget {
  const ArtistDetailPage({
    super.key,
    required this.artistId,
  });

  final String artistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistAsync = ref.watch(artistDetailProvider(artistId));
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
            onPressed: () => ref.refresh(artistDetailProvider(artistId)),
          ),
        ],
      ),
      body: artistAsync.when(
        data: (artist) {
          final tracks = artist.tracks;
          final albums = artist.albums;

          return CustomScrollView(
            slivers: [
              // Header Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.paddingScreen,
                  child: Column(
                    children: [
                      // Artist Avatar
                      ClipOval(
                        child: artist.imageUrl != null &&
                                artist.imageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: artist.imageUrl!,
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 150,
                                  height: 150,
                                  color: AppColors.darkSurfaceElevated,
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 150,
                                  height: 150,
                                  color: AppColors.darkSurfaceElevated,
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 64,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : Container(
                                width: 150,
                                height: 150,
                                decoration: const BoxDecoration(
                                  color: AppColors.darkSurfaceElevated,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 64,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        artist.name,
                        style: AppTypography.display.copyWith(fontSize: 24),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Nghệ sĩ • ${tracks.length} bài hát • ${albums.length} album',
                        style: AppTypography.caption,
                      ),
                      if (artist.bio != null && artist.bio!.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          artist.bio!.trim(),
                          style: AppTypography.secondaryText,
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),

                      // Action Button: Play All Artist Tracks
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
                              'Phát bài hát',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              final firstTrack = tracks.first;
                              ref.read(playerControllerProvider.notifier).playTrack(
                                    firstTrack,
                                    queue: tracks,
                                    source: EventSourceModel(type: 'artist', id: artist.id),
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

              // Albums Section
              if (albums.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Album & Đĩa nhạc',
                      style: AppTypography.sectionTitle,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 190,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      scrollDirection: Axis.horizontal,
                      itemCount: albums.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final album = albums[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.push('/albums/${album.id}'),
                          child: Container(
                            width: 130,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.darkDivider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: album.coverImageUrl != null &&
                                          album.coverImageUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: album.coverImageUrl!,
                                          width: 114,
                                          height: 114,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            width: 114,
                                            height: 114,
                                            color: AppColors.darkSurfaceElevated,
                                            child: const Icon(
                                              Icons.album_rounded,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 114,
                                          height: 114,
                                          color: AppColors.darkSurfaceElevated,
                                          child: const Icon(
                                            Icons.album_rounded,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  album.title,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  album.formattedReleaseYear.isNotEmpty
                                      ? album.formattedReleaseYear
                                      : 'Album',
                                  style: AppTypography.caption.copyWith(fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],

              // Popular Tracks Section
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Bài hát nổi bật',
                    style: AppTypography.sectionTitle,
                  ),
                ),
              ),

              if (tracks.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Nghệ sĩ chưa có bài hát nào.',
                      style: AppTypography.secondaryText,
                    ),
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
                                source: EventSourceModel(type: 'artist', id: artist.id),
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
            message: 'Không thể tải chi tiết nghệ sĩ: $error',
            onRetry: () => ref.refresh(artistDetailProvider(artistId)),
          ),
        ),
      ),
    );
  }
}


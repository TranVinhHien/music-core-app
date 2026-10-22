import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/song_list_item.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../catalog/domain/entities/track_entity.dart';
import '../../events/domain/entities/client_event.dart';
import '../../library/presentation/favorites_controller.dart';
import '../../library/presentation/playlists_controller.dart';
import '../../library/presentation/widgets/add_to_playlist_sheet.dart';
import '../../player/presentation/now_playing_page.dart';
import '../../player/presentation/player_controller.dart';
import '../../songs/presentation/songs_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value?.user;
    final playlistsAsync = ref.watch(playlistsControllerProvider);
    final songsAsync = ref.watch(songsControllerProvider);
    final favoritesAsync = ref.watch(favoritesControllerProvider);
    final favoriteIds =
        favoritesAsync.value?.map((TrackEntity t) => t.id).toSet() ??
            <String>{};

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào, ${user?.fullName ?? "Bạn"} 👋',
              style: AppTypography.screenTitle.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 2),
            const Text(
              'Hôm nay bạn muốn nghe gì?',
              style: AppTypography.caption,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 22),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Huỷ'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(authControllerProvider.notifier).signOut();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(playlistsControllerProvider.future),
            ref.refresh(songsControllerProvider.future),
            ref.refresh(favoritesControllerProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shortcut Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.favorite_rounded,
                        iconColor: AppColors.error,
                        title: 'Yêu thích',
                        subtitle: '${favoritesAsync.value?.length ?? 0} bài',
                        onTap: () => context.go('/favorites'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.queue_music_rounded,
                        iconColor: AppColors.primary,
                        title: 'Playlists',
                        subtitle: '${playlistsAsync.value?.length ?? 0} danh sách',
                        onTap: () => context.go('/playlists'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Playlists Carousel Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Playlist Của Bạn', style: AppTypography.sectionTitle),
                    TextButton(
                      onPressed: () => context.go('/playlists'),
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 140,
                child: playlistsAsync.when(
                  data: (playlists) {
                    if (playlists.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.darkSurface,
                            borderRadius: AppRadius.borderRadiusMd,
                            border: Border.all(color: AppColors.darkDivider),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: const Center(
                            child: Text(
                              'Chưa có playlist. Vào tab Playlists để tạo mới!',
                              style: AppTypography.secondaryText,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      scrollDirection: Axis.horizontal,
                      itemCount: playlists.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final p = playlists[index];
                        return InkWell(
                          borderRadius: AppRadius.borderRadiusMd,
                          onTap: () => context.go('/playlists/${p.id}'),
                          child: Container(
                            width: 120,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurface,
                              borderRadius: AppRadius.borderRadiusMd,
                              border: Border.all(color: AppColors.darkDivider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.darkSurfaceElevated,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.music_note, color: AppColors.primary),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  p.name,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${p.trackCount} bài',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Recent / Featured Songs Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bài Hát Mới & Nổi Bật', style: AppTypography.sectionTitle),
                    TextButton(
                      onPressed: () => context.go('/songs'),
                      child: const Text('Xem thêm'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              songsAsync.when(
                data: (songs) {
                  if (songs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('Kho bài hát hiện đang trống', style: AppTypography.secondaryText),
                      ),
                    );
                  }

                  final displaySongs = songs.take(6).toList();
                  return Column(
                    children: displaySongs.map((track) {
                      final isFav = favoriteIds.contains(track.id);
                      return SongListItem(
                        track: track,
                        isFavorite: isFav,
                        onFavoriteToggle: () {
                          ref.read(favoritesControllerProvider.notifier).toggleFavorite(track);
                        },
                        onAddToPlaylist: () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (_) => SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: AddToPlaylistSheet(track: track),
                            ),
                          );
                        },
                        onTap: () {
                          ref.read(playerControllerProvider.notifier).playTrack(
                                track,
                                queue: songs,
                                source: const EventSourceModel(type: 'home'),
                              );
                          NowPlayingPage.show(context);
                        },
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Lỗi tải bài hát: $e', style: AppTypography.secondaryText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: AppRadius.borderRadiusMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

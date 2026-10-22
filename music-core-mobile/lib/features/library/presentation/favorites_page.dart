import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/song_list_item.dart';
import '../../events/domain/entities/client_event.dart';
import '../../player/presentation/now_playing_page.dart';
import '../../player/presentation/player_controller.dart';
import 'favorites_controller.dart';
import 'widgets/add_to_playlist_sheet.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài Hát Yêu Thích', style: AppTypography.screenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(favoritesControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: favoritesAsync.when(
        data: (favorites) {
          if (favorites.isEmpty) {
            return EmptyStateView(
              icon: Icons.favorite_border_rounded,
              title: 'Chưa có bài hát yêu thích',
              message: 'Bấm vào biểu tượng trái tim ở bất kỳ bài hát nào để lưu vào đây',
              actionLabel: 'Khám Phá Bài Hát',
              onAction: () => context.go('/songs'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(favoritesControllerProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final track = favorites[index];

                return SongListItem(
                  track: track,
                  isFavorite: true,
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
                          queue: favorites,
                          source: const EventSourceModel(type: 'favorites'),
                        );
                    NowPlayingPage.show(context);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(
          message: e.toString(),
          onRetry: () => ref.read(favoritesControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }
}

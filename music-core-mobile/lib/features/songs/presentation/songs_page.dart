import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'songs_controller.dart';

class SongsPage extends ConsumerStatefulWidget {
  const SongsPage({super.key});

  @override
  ConsumerState<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends ConsumerState<SongsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsControllerProvider);
    final favoritesAsync = ref.watch(favoritesControllerProvider);
    final favoriteIds =
        favoritesAsync.value?.map((TrackEntity t) => t.id).toSet() ??
            <String>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho Bài Hát', style: AppTypography.screenTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Tìm bài hát hoặc nghệ sĩ...',
              leading: const Icon(Icons.search, color: AppColors.darkTextMuted),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(songsControllerProvider.notifier).onSearchChanged('');
                    },
                  ),
              ],
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: const WidgetStatePropertyAll(AppColors.darkSurface),
              shape: const WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
              ),
              onChanged: (val) {
                ref.read(songsControllerProvider.notifier).onSearchChanged(val);
                setState(() {});
              },
            ),
          ),
        ),
      ),
      body: songsAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return EmptyStateView(
              title: _searchController.text.isEmpty
                  ? 'Chưa có bài hát nào'
                  : 'Không tìm thấy bài hát',
              message: _searchController.text.isEmpty
                  ? 'Kho bài hát hiện đang trống'
                  : 'Thử tìm kiếm với từ khoá khác',
              icon: Icons.search_off_rounded,
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(songsControllerProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final track = songs[index];
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
                    final query = ref.read(songsQueryProvider);
                    ref.read(playerControllerProvider.notifier).playTrack(
                          track,
                          queue: songs,
                          source: query.isNotEmpty
                              ? EventSourceModel(type: 'search', id: query)
                              : const EventSourceModel(type: 'tracks'),
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
          onRetry: () => ref.read(songsControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }
}

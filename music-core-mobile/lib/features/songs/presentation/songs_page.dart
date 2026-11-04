import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/song_list_item.dart';
import '../../catalog/domain/entities/album_entity.dart';
import '../../catalog/domain/entities/artist_entity.dart';
import '../../catalog/domain/entities/catalog_search_result.dart';
import '../../catalog/domain/entities/track_entity.dart';
import '../../catalog/presentation/search_controller.dart';
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
  late final ScrollController _scrollController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(songsControllerProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final query = val.trim();
      ref.read(catalogSearchQueryProvider.notifier).setQuery(query);
      ref.read(songsControllerProvider.notifier).onSearchChanged(query);
    });
    setState(() {});
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    ref.read(catalogSearchQueryProvider.notifier).setQuery('');
    ref.read(catalogSearchFilterProvider.notifier).setFilter('all');
    ref.read(songsControllerProvider.notifier).onSearchChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(catalogSearchQueryProvider);
    final activeFilter = ref.watch(catalogSearchFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          searchQuery.isEmpty ? 'Kho Bài Hát' : 'Tìm kiếm Catalog',
          style: AppTypography.screenTitle,
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(searchQuery.isNotEmpty ? 108.0 : 60.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Tìm bài hát, album, nghệ sĩ...',
                  leading: const Icon(Icons.search, color: AppColors.darkTextMuted),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: _clearSearch,
                      ),
                  ],
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: const WidgetStatePropertyAll(AppColors.darkSurface),
                  shape: const WidgetStatePropertyAll(
                    RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              if (searchQuery.isNotEmpty)
                _buildFilterChips(activeFilter),
            ],
          ),
        ),
      ),
      body: searchQuery.isEmpty
          ? _buildDefaultSongList()
          : _buildSearchResultsView(searchQuery, activeFilter),
    );
  }

  Widget _buildFilterChips(String activeFilter) {
    final filters = [
      {'key': 'all', 'label': 'Tất cả'},
      {'key': 'tracks', 'label': 'Bài hát'},
      {'key': 'albums', 'label': 'Album'},
      {'key': 'artists', 'label': 'Nghệ sĩ'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: filters.map((f) {
          final isSelected = activeFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.darkSurfaceElevated,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.darkTextSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.darkDivider,
                ),
              ),
              onSelected: (_) {
                ref.read(catalogSearchFilterProvider.notifier).setFilter(f['key']!);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDefaultSongList() {
    final songsAsync = ref.watch(songsControllerProvider);
    final favoritesAsync = ref.watch(favoritesControllerProvider);
    final favoriteIds =
        favoritesAsync.value?.map((TrackEntity t) => t.id).toSet() ??
            <String>{};
    final hasMore = ref.read(songsControllerProvider.notifier).hasMore;

    return songsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const EmptyStateView(
            title: 'Chưa có bài hát nào',
            message: 'Kho bài hát hiện đang trống',
            icon: Icons.music_off_rounded,
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(songsControllerProvider.notifier).refresh(),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: songs.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= songs.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              final track = songs[index];
              final isFav = favoriteIds.contains(track.id);

              return SongListItem(
                track: track,
                isFavorite: isFav,
                onFavoriteToggle: () {
                  ref.read(favoritesControllerProvider.notifier).toggleFavorite(track);
                },
                onAddToPlaylist: () => _showAddToPlaylist(track),
                onTap: () => _playTrack(track, songs),
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
    );
  }

  Widget _buildSearchResultsView(String query, String filter) {
    final searchAsync = ref.watch(catalogSearchProvider);
    final favoritesAsync = ref.watch(favoritesControllerProvider);
    final favoriteIds =
        favoritesAsync.value?.map((TrackEntity t) => t.id).toSet() ??
            <String>{};

    return searchAsync.when(
      data: (result) {
        if (result.isEmpty) {
          return EmptyStateView(
            title: 'Không tìm thấy kết quả',
            message: 'Không tìm thấy bài hát, album hay nghệ sĩ phù hợp với "$query"',
            icon: Icons.search_off_rounded,
          );
        }

        return CustomScrollView(
          slivers: [
            // ARTISTS SECTION
            if ((filter == 'all' || filter == 'artists') && result.artists.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nghệ sĩ (${result.artists.total})',
                        style: AppTypography.sectionTitle.copyWith(fontSize: 16),
                      ),
                      if (filter == 'all' && result.artists.total > result.artists.items.length)
                        TextButton(
                          onPressed: () {
                            ref.read(catalogSearchFilterProvider.notifier).setFilter('artists');
                          },
                          child: const Text('Xem tất cả'),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: result.artists.items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final artist = result.artists.items[index];
                      return _buildArtistItem(artist);
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],

            // ALBUMS SECTION
            if ((filter == 'all' || filter == 'albums') && result.albums.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Album (${result.albums.total})',
                        style: AppTypography.sectionTitle.copyWith(fontSize: 16),
                      ),
                      if (filter == 'all' && result.albums.total > result.albums.items.length)
                        TextButton(
                          onPressed: () {
                            ref.read(catalogSearchFilterProvider.notifier).setFilter('albums');
                          },
                          child: const Text('Xem tất cả'),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 185,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: result.albums.items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final album = result.albums.items[index];
                      return _buildAlbumItem(album);
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],

            // TRACKS SECTION
            if ((filter == 'all' || filter == 'tracks') && result.tracks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bài hát (${result.tracks.total})',
                        style: AppTypography.sectionTitle.copyWith(fontSize: 16),
                      ),
                      if (filter == 'all' && result.tracks.total > result.tracks.items.length)
                        TextButton(
                          onPressed: () {
                            ref.read(catalogSearchFilterProvider.notifier).setFilter('tracks');
                          },
                          child: const Text('Xem tất cả'),
                        ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = result.tracks.items[index];
                    final isFav = favoriteIds.contains(track.id);

                    return SongListItem(
                      track: track,
                      isFavorite: isFav,
                      onFavoriteToggle: () {
                        ref.read(favoritesControllerProvider.notifier).toggleFavorite(track);
                      },
                      onAddToPlaylist: () => _showAddToPlaylist(track),
                      onTap: () => _playTrack(track, result.tracks.items),
                    );
                  },
                  childCount: result.tracks.items.length,
                ),
              ),
            ],

            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => ErrorStateView(
        message: 'Lỗi tìm kiếm: $e',
        onRetry: () => ref.refresh(catalogSearchProvider),
      ),
    );
  }

  Widget _buildArtistItem(ArtistEntity artist) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/artists/${artist.id}'),
      child: Container(
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            ClipOval(
              child: artist.imageUrl != null && artist.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: artist.imageUrl!,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 68,
                        height: 68,
                        color: AppColors.darkSurfaceElevated,
                        child: const Icon(Icons.person, color: AppColors.primary),
                      ),
                    )
                  : Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: AppColors.darkSurfaceElevated,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: AppColors.primary),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              artist.name,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              'Nghệ sĩ',
              style: AppTypography.caption.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumItem(AlbumEntity album) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/albums/${album.id}'),
      child: Container(
        width: 124,
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
              child: album.coverImageUrl != null && album.coverImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: album.coverImageUrl!,
                      width: 108,
                      height: 108,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 108,
                        height: 108,
                        color: AppColors.darkSurfaceElevated,
                        child: const Icon(Icons.album_rounded, color: AppColors.primary),
                      ),
                    )
                  : Container(
                      width: 108,
                      height: 108,
                      color: AppColors.darkSurfaceElevated,
                      child: const Icon(Icons.album_rounded, color: AppColors.primary),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              album.title,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              album.artistName,
              style: AppTypography.caption.copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylist(TrackEntity track) {
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
  }

  void _playTrack(TrackEntity track, List<TrackEntity> queue) {
    final query = ref.read(catalogSearchQueryProvider);
    ref.read(playerControllerProvider.notifier).playTrack(
          track,
          queue: queue,
          source: query.isNotEmpty
              ? EventSourceModel(type: 'search', id: query)
              : const EventSourceModel(type: 'tracks'),
        );
    NowPlayingPage.show(context);
  }
}

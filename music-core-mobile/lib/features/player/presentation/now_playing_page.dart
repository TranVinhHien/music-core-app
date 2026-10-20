import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../catalog/domain/entities/track_entity.dart';
import '../../library/presentation/favorites_controller.dart';
import '../../library/presentation/widgets/add_to_playlist_sheet.dart';
import '../../offline/presentation/offline_controller.dart';
import 'player_controller.dart';
import 'player_state.dart';

class NowPlayingPage extends ConsumerWidget {
  const NowPlayingPage({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.darkBackground,
      builder: (_) => const NowPlayingPage(),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayerState playerState = ref.watch(playerControllerProvider);
    final track = playerState.currentTrack;

    if (track == null) {
      return const Scaffold(
        body: Center(child: Text('Không có bài hát nào đang phát')),
      );
    }

    final favoritesAsync = ref.watch(favoritesControllerProvider);
    final isFavorite = favoritesAsync.value?.any((TrackEntity t) => t.id == track.id) ?? false;
    final activeDownloads = ref.watch(downloadProgressControllerProvider);
    final downloadProgress = activeDownloads[track.id];
    final downloadedTracks = ref.watch(offlineTracksStreamProvider).asData?.value ?? [];
    final isDownloaded = track.isDownloaded || downloadedTracks.any((TrackEntity t) => t.id == track.id);

    final maxDurationMs = playerState.duration.inMilliseconds > 0
        ? playerState.duration.inMilliseconds.toDouble()
        : 1.0;
    final currentPosMs = playerState.position.inMilliseconds
        .clamp(0, maxDurationMs.toInt())
        .toDouble();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              'ĐANG PHÁT',
              style: AppTypography.caption.copyWith(
                letterSpacing: 1.5,
                color: AppColors.darkTextMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (track.albumTitle != null && track.albumTitle!.isNotEmpty)
              Text(
                track.albumTitle!,
                style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_rounded),
            tooltip: 'Thêm vào playlist',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.darkSurface,
                builder: (_) => AddToPlaylistSheet(track: track),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Ambient blurred background using song's cover image
          if (track.coverImageUrl != null && track.coverImageUrl!.isNotEmpty) ...[
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: CachedNetworkImage(
                  imageUrl: track.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      AppColors.darkBackground.withValues(alpha: 0.85),
                      AppColors.darkBackground.withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),
          ],
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                children: [
                  const Spacer(),
                  // Big Artwork
                  Center(
                    child: Hero(
                      tag: 'now_playing_artwork_${track.id}',
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceElevated,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 36,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (track.coverImageUrl != null && track.coverImageUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: track.coverImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.music_note_rounded, size: 80, color: AppColors.primary),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.4),
                                  AppColors.darkSurfaceElevated,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.music_note_rounded, size: 80, color: AppColors.primary),
                            ),
                          ),
                  ),
                ),
              ),
              const Spacer(),
              // Track Info + Favorite Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: AppTypography.display.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track.artistName,
                          style: AppTypography.secondaryText.copyWith(
                            fontSize: 16,
                            color: AppColors.darkTextMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (downloadProgress != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          value: downloadProgress > 0 ? downloadProgress : null,
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (isDownloaded)
                    IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 28),
                      tooltip: 'Đã tải offline',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bài hát đã được tải về máy để nghe offline')),
                        );
                      },
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: AppColors.darkTextMuted, size: 28),
                      tooltip: 'Tải để nghe offline',
                      onPressed: () {
                        ref.read(downloadProgressControllerProvider.notifier).downloadTrack(track);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đang tải bài hát: ${track.title}')),
                        );
                      },
                    ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFavorite ? AppColors.error : AppColors.darkTextMuted,
                      size: 28,
                    ),
                    onPressed: () {
                      ref.read(favoritesControllerProvider.notifier).toggleFavorite(track);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Progress Bar (Slider)
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.darkSurfaceElevated,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      min: 0,
                      max: maxDurationMs,
                      value: currentPosMs,
                      onChanged: (val) {
                        ref
                            .read(playerControllerProvider.notifier)
                            .seek(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(playerState.position),
                          style: AppTypography.caption.copyWith(color: AppColors.darkTextMuted),
                        ),
                        Text(
                          _formatDuration(playerState.duration),
                          style: AppTypography.caption.copyWith(color: AppColors.darkTextMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Playback Controls Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Shuffle
                  IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: playerState.isShuffle ? AppColors.primary : AppColors.darkTextMuted,
                      size: 24,
                    ),
                    tooltip: 'Trộn bài',
                    onPressed: () {
                      ref.read(playerControllerProvider.notifier).toggleShuffle();
                    },
                  ),
                  // Skip Previous
                  IconButton(
                    icon: const Icon(
                      Icons.skip_previous_rounded,
                      size: 38,
                    ),
                    tooltip: 'Bài trước',
                    onPressed: () {
                      ref.read(playerControllerProvider.notifier).skipPrevious();
                    },
                  ),
                  // Play/Pause Big Button
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: playerState.isBuffering
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              playerState.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 38,
                              color: Colors.white,
                            ),
                      onPressed: () {
                        ref.read(playerControllerProvider.notifier).togglePlayPause();
                      },
                    ),
                  ),
                  // Skip Next
                  IconButton(
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      size: 38,
                    ),
                    tooltip: 'Bài kế tiếp',
                    onPressed: () {
                      ref.read(playerControllerProvider.notifier).skipNext();
                    },
                  ),
                  // Loop/Repeat
                  IconButton(
                    icon: Icon(
                      playerState.loopMode == ja.LoopMode.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      color: playerState.loopMode != ja.LoopMode.off
                          ? AppColors.primary
                          : AppColors.darkTextMuted,
                      size: 24,
                    ),
                    tooltip: 'Lặp lại',
                    onPressed: () {
                      ref.read(playerControllerProvider.notifier).toggleLoopMode();
                    },
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    ],
  ),
);
  }
}

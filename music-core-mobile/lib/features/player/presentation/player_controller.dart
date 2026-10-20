import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:just_audio_background/just_audio_background.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/dependencies.dart';
import '../../../core/utils/audio_url_resolver.dart';
import '../../catalog/domain/entities/track_entity.dart';
import 'player_state.dart';

part 'player_controller.g.dart';

@Riverpod(keepAlive: true)
class PlayerController extends _$PlayerController {
  final ja.AudioPlayer _audioPlayer = ja.AudioPlayer();
  StreamSubscription<ja.PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  @override
  PlayerState build() {
    _initStreams();
    ref.onDispose(() {
      _playerStateSub?.cancel();
      _positionSub?.cancel();
      _durationSub?.cancel();
      _audioPlayer.dispose();
    });
    return const PlayerState();
  }

  void _initStreams() {
    _initAudioSession();
    _playerStateSub = _audioPlayer.playerStateStream.listen((jaState) {
      state = state.copyWith(
        isPlaying: jaState.playing,
        isBuffering: jaState.processingState == ja.ProcessingState.buffering ||
            jaState.processingState == ja.ProcessingState.loading,
      );

      if (jaState.processingState == ja.ProcessingState.completed) {
        skipNext();
      }
    });

    _positionSub = _audioPlayer.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _durationSub = _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });
  }

  Future<void> playTrack(TrackEntity track, {List<TrackEntity>? queue}) async {
    final trackList = (queue != null && queue.isNotEmpty) ? queue : [track];
    final index = trackList.indexWhere((TrackEntity t) => t.id == track.id);
    final activeIndex = index >= 0 ? index : 0;

    // Estimate initial duration from track durationMs if available
    final initialDuration = track.durationMs != null
        ? Duration(milliseconds: track.durationMs!)
        : Duration.zero;

    state = state.copyWith(
      currentTrack: track,
      queue: trackList,
      currentIndex: activeIndex,
      position: Duration.zero,
      duration: initialDuration,
      isPlaying: true,
      isBuffering: true,
    );

    try {
      final offlineRepo = ref.read(offlineRepositoryProvider);
      final localTrack = await offlineRepo.getTrackById(track.id);
      final effectiveLocalPath = track.localFilePath ?? localTrack?.localFilePath;

      final mediaItem = MediaItem(
        id: track.id,
        title: track.title,
        artist: track.artistName,
        album: track.albumTitle ?? 'Music Core',
        artUri: (track.coverImageUrl != null && track.coverImageUrl!.isNotEmpty)
            ? Uri.tryParse(track.coverImageUrl!)
            : null,
        duration: track.durationMs != null
            ? Duration(milliseconds: track.durationMs!)
            : null,
      );

      final ja.AudioSource audioSource;
      if (effectiveLocalPath != null && File(effectiveLocalPath).existsSync()) {
        audioSource = ja.AudioSource.file(effectiveLocalPath, tag: mediaItem);
      } else if (track.fileUrl != null && track.fileUrl!.trim().isNotEmpty) {
        final streamUrl = AudioUrlResolver.resolve(track.fileUrl!.trim());
        audioSource = ja.AudioSource.uri(Uri.parse(streamUrl), tag: mediaItem);
      } else {
        state = state.copyWith(isBuffering: false);
        return;
      }

      final loadedDuration = await _audioPlayer.setAudioSource(audioSource);
      if (loadedDuration != null) {
        state = state.copyWith(duration: loadedDuration);
      }
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
      state = state.copyWith(isBuffering: false);
    }
  }

  Future<void> togglePlayPause() async {
    if (!state.hasTrack) return;
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> skipNext() async {
    if (state.queue.isEmpty) return;

    int nextIndex = state.currentIndex + 1;
    if (state.isShuffle && state.queue.length > 1) {
      nextIndex = (state.currentIndex + 1) % state.queue.length;
    }

    if (nextIndex < state.queue.length) {
      final nextTrack = state.queue[nextIndex];
      await playTrack(nextTrack, queue: state.queue);
    } else if (state.loopMode == ja.LoopMode.all) {
      await playTrack(state.queue.first, queue: state.queue);
    }
  }

  Future<void> skipPrevious() async {
    if (state.queue.isEmpty) return;

    if (state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (state.currentIndex > 0) {
      final prevTrack = state.queue[state.currentIndex - 1];
      await playTrack(prevTrack, queue: state.queue);
    } else {
      await seek(Duration.zero);
    }
  }

  void toggleShuffle() {
    state = state.copyWith(isShuffle: !state.isShuffle);
  }

  void toggleLoopMode() {
    final nextMode = switch (state.loopMode) {
      ja.LoopMode.off => ja.LoopMode.all,
      ja.LoopMode.all => ja.LoopMode.one,
      ja.LoopMode.one => ja.LoopMode.off,
    };
    _audioPlayer.setLoopMode(nextMode);
    state = state.copyWith(loopMode: nextMode);
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('Error configuring audio session: $e');
    }
  }
}

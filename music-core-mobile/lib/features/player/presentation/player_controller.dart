import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/dependencies.dart';
import '../../catalog/domain/entities/track_entity.dart';
import '../../events/domain/entities/client_event.dart';
import '../domain/entities/transition_plan.dart';
import '../domain/repositories/transition_repository.dart';
import 'player_state.dart';
import 'smart_crossfade_audio_player.dart';
import 'smart_transition_controller.dart';

part 'player_controller.g.dart';

@Riverpod(keepAlive: true)
class PlayerController extends _$PlayerController {
  SmartCrossfadeAudioPlayer? _playerInstance;
  SmartCrossfadeAudioPlayer get _player => _playerInstance!;
  StreamSubscription<ja.PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<AutoDjTransitionResponse?>? _transitionSub;

  EventSourceModel? _currentSource;
  bool _isNaturalCompletion = false;

  /// Tracks IDs of recently played tracks with their playback timestamps to avoid immediate repetition
  final Map<String, DateTime> _recentlyPlayedHistory = {};

  /// Records a track as recently played with current timestamp
  void _recordRecentlyPlayed(String trackId) {
    _recentlyPlayedHistory[trackId] = DateTime.now();
  }

  /// Returns track IDs played within the last 1 hour
  List<String> _getRecentlyPlayedExcludedIds() {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    _recentlyPlayedHistory.removeWhere((_, time) => time.isBefore(oneHourAgo));
    return _recentlyPlayedHistory.keys.toList();
  }

  /// Returns the next track in current queue or loops to start for transition planning
  TrackEntity? _getNextTrackInQueue() {
    if (state.queue.isEmpty) return null;
    final nextIndex = state.currentIndex + 1;
    if (nextIndex < state.queue.length) {
      return state.queue[nextIndex];
    }
    if (state.queue.isNotEmpty && state.queue.first.id != state.currentTrack?.id) {
      return state.queue.first;
    }
    return null;
  }

  /// Exposes the underlying dual-deck crossfade engine
  SmartCrossfadeAudioPlayer get smartPlayer => _player;

  @override
  PlayerState build() {
    TransitionRepository? transitionRepo;
    try {
      transitionRepo = ref.read(transitionRepositoryProvider);
    } catch (_) {}

    if (_playerInstance == null) {
      _playerInstance = SmartCrossfadeAudioPlayer(
        transitionRepository: transitionRepo,
        getExcludeTrackIds: () => _getRecentlyPlayedExcludedIds(),
        getNextTrackFromQueue: () => _getNextTrackInQueue(),
        onTrackTransitioned: (newTrack) {
          _handleAutoDjTrackTransitioned(newTrack);
        },
        onCrossfadeStarted: (nextTrack) {
          state = state.copyWith(isCrossfading: true);
        },
        onError: (error) {
          debugPrint('[PlayerController] Audio playback error: $error');
          state = state.copyWith(isBuffering: false);
        },
      );
      _initStreams();
    }

    final isSmartEnabled = ref.read(smartTransitionControllerProvider);
    _player.setSmartTransitionEnabled(isSmartEnabled);

    // Listen to settings toggle without triggering a rebuild of the player controller
    ref.listen<bool>(smartTransitionControllerProvider, (previous, next) {
      _playerInstance?.setSmartTransitionEnabled(next);
    });

    ref.onDispose(() {
      _playerStateSub?.cancel();
      _positionSub?.cancel();
      _durationSub?.cancel();
      _transitionSub?.cancel();
      _playerInstance?.dispose();
      _playerInstance = null;
    });

    return const PlayerState();
  }

  void _initStreams() {
    SmartCrossfadeAudioPlayer.initAudioSession();

    _playerStateSub = _player.playerStateStream.listen((jaState) {
      state = state.copyWith(
        isPlaying: jaState.playing,
        isBuffering: jaState.processingState == ja.ProcessingState.buffering ||
            jaState.processingState == ja.ProcessingState.loading,
      );

      if (jaState.processingState == ja.ProcessingState.completed) {
        final current = state.currentTrack;
        if (current != null) {
          _isNaturalCompletion = true;
          ref.read(eventTrackerProvider).trackCompleted(
                trackId: current.id,
                durationMs: state.duration.inMilliseconds,
                listenedMs: state.position.inMilliseconds,
                source: _currentSource,
              );
        }
        _handleTrackEnded();
      }
    });

    _positionSub = _player.positionStream.listen((position) {
      state = state.copyWith(
        position: position,
        isCrossfading: _player.isCrossfading,
      );
    });

    _durationSub = _player.durationStream.listen((duration) {
      if (duration != null) {
        final trackDurationMs = state.currentTrack?.durationMs;
        if (trackDurationMs != null && trackDurationMs > 0) {
          final catalogDuration = Duration(milliseconds: trackDurationMs);
          final diffMs = (duration.inMilliseconds - trackDurationMs).abs();
          // Retain authoritative catalog durationMs to prevent inaccurate stream bitrate estimations
          // (which can falsely inflate a 3-minute song to 7-10 minutes over HTTP streaming).
          if (diffMs <= 3000) {
            state = state.copyWith(duration: duration);
          } else {
            state = state.copyWith(duration: catalogDuration);
          }
        } else {
          state = state.copyWith(duration: duration);
        }
      }
    });

    _transitionSub = _player.transitionPlanStream.listen((plan) {
      state = state.copyWith(currentTransitionPlan: plan);
      if (plan != null) {
        final nextTrack = plan.nextTrack.toTrackEntity();
        unawaited(ref.read(audioPrecacheServiceProvider).precacheTrack(nextTrack));
      }
    });
  }

  void _handleAutoDjTrackTransitioned(TrackEntity newTrack) {
    _recordRecentlyPlayed(newTrack.id);

    // If new track was pre-cached on local storage, resolve localFilePath for instant playback
    final precachedPath = ref.read(audioPrecacheServiceProvider).getCachedPath(newTrack.id);
    final effectiveTrack = (newTrack.localFilePath == null && precachedPath != null)
        ? newTrack.copyWith(localFilePath: precachedPath)
        : newTrack;

    final current = state.currentTrack;
    if (current != null) {
      _isNaturalCompletion = true;
      ref.read(eventTrackerProvider).trackCompleted(
            trackId: current.id,
            durationMs: state.duration.inMilliseconds,
            listenedMs: state.position.inMilliseconds,
            source: _currentSource,
          );
    }
    _isNaturalCompletion = false;

    // Check if newTrack matches next item in queue or insert
    final currentQ = List<TrackEntity>.from(state.queue);
    final nextIndex = state.currentIndex + 1;
    int targetIndex = nextIndex;

    if (nextIndex < currentQ.length && currentQ[nextIndex].id == newTrack.id) {
      targetIndex = nextIndex;
    } else {
      final existingIndex = currentQ.indexWhere((t) => t.id == newTrack.id);
      if (existingIndex >= 0) {
        targetIndex = existingIndex;
      } else {
        currentQ.insert(nextIndex.clamp(0, currentQ.length), newTrack);
        targetIndex = nextIndex;
      }
    }

    final newTrackDuration = (effectiveTrack.durationMs != null && effectiveTrack.durationMs! > 0)
        ? Duration(milliseconds: effectiveTrack.durationMs!)
        : Duration.zero;

    state = state.copyWith(
      currentTrack: effectiveTrack,
      queue: currentQ,
      currentIndex: targetIndex,
      isCrossfading: false,
      duration: newTrackDuration,
      position: Duration.zero,
    );

    // Track playback start event for new track
    ref.read(eventTrackerProvider).trackStarted(
          trackId: effectiveTrack.id,
          durationMs: effectiveTrack.durationMs ?? 0,
          positionMs: 0,
          source: _currentSource,
        );

    // Automatically play the new track from pre-cached disk storage
    unawaited(playTrack(effectiveTrack, queue: currentQ, source: _currentSource));
  }

  Future<void> playTrack(
    TrackEntity track, {
    List<TrackEntity>? queue,
    EventSourceModel? source,
    AutoDjTransitionResponse? transitionPlan,
  }) async {
    final trackList = (queue != null && queue.isNotEmpty) ? queue : [track];
    final index = trackList.indexWhere((TrackEntity t) => t.id == track.id);
    final activeIndex = index >= 0 ? index : 0;

    _currentSource = source ?? _currentSource;
    _isNaturalCompletion = false;

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
      isCrossfading: false,
    );

    // Track playback start event
    ref.read(eventTrackerProvider).trackStarted(
          trackId: track.id,
          durationMs: track.durationMs ?? 0,
          positionMs: 0,
          source: _currentSource,
        );

    try {
      final offlineRepo = ref.read(offlineRepositoryProvider);
      final localTrack = await offlineRepo.getTrackById(track.id);
      final precacheService = ref.read(audioPrecacheServiceProvider);
      final precachedPath = precacheService.getCachedPath(track.id);

      final effectiveLocalPath =
          track.localFilePath ?? localTrack?.localFilePath ?? precachedPath;

      if ((effectiveLocalPath == null ||
              !File(effectiveLocalPath).existsSync()) &&
          (track.fileUrl == null || track.fileUrl!.trim().isEmpty)) {
        state = state.copyWith(isBuffering: false);
        return;
      }

      final effectiveTrack = (effectiveLocalPath != null)
          ? track.copyWith(localFilePath: effectiveLocalPath)
          : track;

      _recordRecentlyPlayed(effectiveTrack.id);
      final excludeIds = _getRecentlyPlayedExcludedIds();

      // Trigger eager background pre-cache for the upcoming track in queue
      final nextInQueue = _getNextTrackInQueue();
      if (nextInQueue != null) {
        unawaited(precacheService.precacheTrack(nextInQueue));
      }

      final loadedDuration = await _player.playTrack(
        effectiveTrack,
        transitionPlan: transitionPlan,
        excludeTrackIds: excludeIds,
      );

      final trackDurMs = effectiveTrack.durationMs;
      if (trackDurMs != null && trackDurMs > 0) {
        final catalogDur = Duration(milliseconds: trackDurMs);
        if (loadedDuration != null &&
            (loadedDuration.inMilliseconds - trackDurMs).abs() <= 3000) {
          state = state.copyWith(duration: loadedDuration);
        } else {
          state = state.copyWith(duration: catalogDur);
        }
      } else if (loadedDuration != null) {
        state = state.copyWith(duration: loadedDuration);
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      state = state.copyWith(isBuffering: false);
    }
  }

  Future<void> togglePlayPause() async {
    if (!state.hasTrack) return;
    if (_player.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> pause() async {
    final current = state.currentTrack;
    if (current != null) {
      ref.read(eventTrackerProvider).trackPaused(
            trackId: current.id,
            positionMs: state.position.inMilliseconds,
            listenedMs: state.position.inMilliseconds,
            source: _currentSource,
          );
    }
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }

  Future<void> seek(Duration position) async {
    final current = state.currentTrack;
    if (current != null) {
      ref.read(eventTrackerProvider).trackSeeked(
            trackId: current.id,
            fromPositionMs: state.position.inMilliseconds,
            toPositionMs: position.inMilliseconds,
            source: _currentSource,
          );
    }
    await _player.seek(position);
  }

  Future<void> _handleTrackEnded() async {
    final isSmart = ref.read(smartTransitionControllerProvider);
    final plan = state.currentTransitionPlan;

    // If Smart Auto-DJ transition is ON and has a planned next track, transition immediately!
    if (isSmart && plan != null) {
      final nextTrack = plan.nextTrack.toTrackEntity();
      debugPrint('[PlayerController] Natural completion: Auto-DJ advancing to ${nextTrack.title}');
      await playTrack(nextTrack, queue: state.queue, source: _currentSource);
      return;
    }

    // Otherwise, advance through queue normally
    await skipNext();
  }

  Future<void> skipNext() async {
    if (state.queue.isEmpty) return;

    final current = state.currentTrack;

    if (state.loopMode == ja.LoopMode.one && current != null) {
      await seek(Duration.zero);
      await resume();
      return;
    }

    int nextIndex = state.currentIndex + 1;
    if (state.isShuffle && state.queue.length > 1) {
      nextIndex = (state.currentIndex + 1) % state.queue.length;
    }

    // If reached the end of queue, wrap around to first track so playback never abruptly stops
    final TrackEntity? nextTrack = nextIndex < state.queue.length
        ? state.queue[nextIndex]
        : (state.queue.isNotEmpty ? state.queue.first : null);

    if (!_isNaturalCompletion && current != null) {
      ref.read(eventTrackerProvider).trackSkipped(
            trackId: current.id,
            durationMs: state.duration.inMilliseconds,
            positionMs: state.position.inMilliseconds,
            listenedMs: state.position.inMilliseconds,
            nextTrackId: nextTrack?.id,
            source: _currentSource,
          );
    }
    _isNaturalCompletion = false;

    if (nextTrack != null) {
      await playTrack(nextTrack, queue: state.queue, source: _currentSource);
    }
  }

  Future<void> skipPrevious() async {
    if (state.queue.isEmpty) return;

    final current = state.currentTrack;
    if (state.position.inSeconds > 3) {
      if (current != null) {
        ref.read(eventTrackerProvider).trackReplayed(
              trackId: current.id,
              positionMs: state.position.inMilliseconds,
              source: _currentSource,
            );
      }
      await seek(Duration.zero);
      return;
    }

    if (state.currentIndex > 0) {
      final prevTrack = state.queue[state.currentIndex - 1];
      if (current != null) {
        ref.read(eventTrackerProvider).trackSkipped(
              trackId: current.id,
              durationMs: state.duration.inMilliseconds,
              positionMs: state.position.inMilliseconds,
              listenedMs: state.position.inMilliseconds,
              nextTrackId: prevTrack.id,
              source: _currentSource,
            );
      }
      await playTrack(prevTrack, queue: state.queue, source: _currentSource);
    } else {
      if (current != null) {
        ref.read(eventTrackerProvider).trackReplayed(
              trackId: current.id,
              positionMs: state.position.inMilliseconds,
              source: _currentSource,
            );
      }
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
    _player.setLoopMode(nextMode);
    state = state.copyWith(loopMode: nextMode);
  }
}

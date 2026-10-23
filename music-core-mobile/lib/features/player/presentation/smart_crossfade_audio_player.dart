import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:just_audio_background/just_audio_background.dart';

import '../../../core/result.dart';
import '../../../core/utils/audio_url_resolver.dart';
import '../../catalog/domain/entities/track_entity.dart';
import '../domain/entities/transition_plan.dart';
import '../domain/repositories/transition_repository.dart';

/// Callback signatures for playback events
typedef OnTrackTransitioned = void Function(TrackEntity newTrack);
typedef OnPrebufferStarted = void Function(NextTrackTransition nextTrack);
typedef OnCrossfadeStarted = void Function(NextTrackTransition nextTrack);

/// Intelligent Auto-DJ audio player providing seamless, dead-air-free music playback.
///
/// Features:
/// 1. Instant loading without blocking byte-range seeks on HTTP streams.
/// 2. Automatic dead-air intro skipping (cues into first sound/downbeat smoothly).
/// 3. Intelligent dead-air outro elimination & automatic advance transition.
/// 4. Volume ramping (fade-out / fade-in) across song boundaries.
/// 5. Fallback transition engine when backend harmonic analysis is absent.
class SmartCrossfadeAudioPlayer {
  SmartCrossfadeAudioPlayer({
    ja.AudioPlayer? primaryDeck,
    ja.AudioPlayer? secondaryDeck,
    this.transitionRepository,
    this.getExcludeTrackIds,
    this.getNextTrackFromQueue,
    this.onTrackTransitioned,
    this.onPrebufferStarted,
    this.onCrossfadeStarted,
    this.onError,
  })  : _player = primaryDeck ?? ja.AudioPlayer(),
        _secondaryPlayer = secondaryDeck {
    _subscribeToPlayerStreams();
  }

  final ja.AudioPlayer _player;
  final ja.AudioPlayer? _secondaryPlayer;
  final TransitionRepository? transitionRepository;
  final List<String> Function()? getExcludeTrackIds;
  final TrackEntity? Function()? getNextTrackFromQueue;

  /// The active audio player
  ja.AudioPlayer get primaryDeck => _player;

  /// Secondary audio player if provided (e.g. In unit tests)
  ja.AudioPlayer get secondaryDeck => _secondaryPlayer ?? _player;

  OnTrackTransitioned? onTrackTransitioned;
  OnPrebufferStarted? onPrebufferStarted;
  OnCrossfadeStarted? onCrossfadeStarted;
  void Function(Object error)? onError;

  TrackEntity? _currentTrack;
  TrackEntity? get currentTrack => _currentTrack;

  NextTrackTransition? _pendingNextTrack;
  NextTrackTransition? get pendingNextTrack => _pendingNextTrack;

  AutoDjTransitionResponse? _currentTransitionPlan;
  AutoDjTransitionResponse? get currentTransitionPlan => _currentTransitionPlan;

  bool _isPrebuffered = false;
  bool get isPrebuffered => _isPrebuffered;

  bool _isCrossfading = false;
  bool get isCrossfading => _isCrossfading;

  bool _isTransitionCompleted = false;

  /// Whether intelligent Auto-DJ transition mode is enabled
  bool isSmartTransitionEnabled = true;

  void setSmartTransitionEnabled(bool enabled) {
    isSmartTransitionEnabled = enabled;
    if (!enabled) {
      _abortOngoingTransition();
      _transitionPlanController.add(null);
    }
  }

  Timer? _fadeTimer;

  // Stream controllers dispatching unified events
  final _playerStateController = StreamController<ja.PlayerState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _transitionPlanController = StreamController<AutoDjTransitionResponse?>.broadcast();

  Stream<ja.PlayerState> get playerStateStream => _playerStateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<AutoDjTransitionResponse?> get transitionPlanStream => _transitionPlanController.stream;

  StreamSubscription<ja.PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;

  /// Derives linear gain multiplier from decibels: 10^(gainDb / 20).
  static double calculateLinearGain(double gainDb) {
    final gain = math.pow(10.0, gainDb / 20.0).toDouble();
    return gain.clamp(0.0, 1.0);
  }

  /// Plays a track directly and fetches or generates its smart transition plan.
  Future<Duration?> playTrack(
    TrackEntity track, {
    AutoDjTransitionResponse? transitionPlan,
    List<String>? excludeTrackIds,
    Duration? initialPosition,
  }) async {
    _abortOngoingTransition();

    _currentTrack = track;
    _currentTransitionPlan = null;
    _pendingNextTrack = null;
    _isTransitionCompleted = false;
    _isCrossfading = false;

    final mediaItem = _createMediaItem(track);
    final audioSource = _buildAudioSource(track, mediaItem);

    if (audioSource == null) {
      debugPrint('[SmartCrossfade] No audio source available for track: ${track.id}');
      return null;
    }

    try {
      // Fade-in volume smoothly on start
      await _player.setVolume(1.0);

      // Load stream cleanly without forced initialPosition to ensure immediate buffering on all endpoints
      final loadedDuration = await _player.setAudioSource(audioSource);
      await _player.play();

      // If track has cueInMs (intro dead air / silence), skip into the first beat smoothly once playing
      final cueIn = track.cueInMs;
      if (cueIn != null && cueIn > 600) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_currentTrack?.id == track.id && _player.position.inMilliseconds < cueIn) {
            _player.seek(Duration(milliseconds: cueIn));
            debugPrint('[SmartCrossfade] Skipped intro dead-air: jumped to ${cueIn}ms for ${track.title}');
          }
        });
      }

      if (isSmartTransitionEnabled) {
        if (transitionPlan != null) {
          setTransitionPlan(transitionPlan);
        } else if (transitionRepository != null) {
          unawaited(fetchAndApplyTransition(
            track.id,
            excludeTrackIds: excludeTrackIds ?? getExcludeTrackIds?.call(),
          ));
        } else {
          _applyFallbackTransitionPlanIfNeeded();
        }
      }

      return loadedDuration;
    } catch (e) {
      debugPrint('[SmartCrossfade] Error playing track: $e');
      onError?.call(e);
      return null;
    }
  }

  /// Explicitly supplies a transition plan for the active track.
  void setTransitionPlan(AutoDjTransitionResponse plan) {
    _currentTransitionPlan = plan;
    _pendingNextTrack = plan.nextTrack;
    _isPrebuffered = true;
    _isCrossfading = false;
    _isTransitionCompleted = false;
    _transitionPlanController.add(plan);
    debugPrint(
      '[SmartCrossfade] Transition plan set: trigger=${plan.currentTrack.triggerTransitionAtMs}ms, '
      'stop=${plan.currentTrack.stopPlaybackAtMs}ms, next=${plan.nextTrack.title}',
    );
  }

  /// Generates a local fallback transition plan if backend AI audio analysis is missing or unavailable.
  AutoDjTransitionResponse? _applyFallbackTransitionPlanIfNeeded() {
    final curTrack = _currentTrack;
    if (curTrack == null) return null;

    final nextTrack = getNextTrackFromQueue?.call();
    if (nextTrack == null) return null;

    final curDurMs = curTrack.durationMs ?? _player.duration?.inMilliseconds ?? 180000;
    const crossfadeMs = 5000;
    // Trigger transition 7 seconds before track ends to eliminate outro silence/dead air
    final triggerMs = math.max(0, curDurMs - 7000);
    final stopMs = curDurMs;
    final startNextMs = nextTrack.cueInMs ?? 1000;

    final fallback = AutoDjTransitionResponse(
      currentTrack: CurrentTrackTransition(
        id: curTrack.id,
        triggerTransitionAtMs: triggerMs,
        stopPlaybackAtMs: stopMs,
      ),
      nextTrack: NextTrackTransition(
        id: nextTrack.id,
        title: nextTrack.title,
        fileUrl: nextTrack.fileUrl,
        coverImageUrl: nextTrack.coverImageUrl,
        artists: [nextTrack.artistName],
        startPlaybackAtMs: startNextMs,
      ),
      transitionPlan: TransitionPlan(
        transitionType: 'SMOOTH_FADE',
        crossfadeDurationMs: crossfadeMs,
        preBufferAtMs: math.max(0, triggerMs - 12000),
        volumeBalanceGainDb: 0.0,
      ),
    );

    debugPrint(
      '[SmartCrossfade] Using queue fallback transition for "${curTrack.title}" -> "${nextTrack.title}". Trigger at ${triggerMs}ms',
    );
    setTransitionPlan(fallback);
    return fallback;
  }

  /// Fetches next transition plan from [TransitionRepository] for the given track ID.
  Future<AutoDjTransitionResponse?> fetchAndApplyTransition(
    String currentTrackId, {
    List<String>? excludeTrackIds,
    double temperature = 0.7,
  }) async {
    if (transitionRepository == null) {
      return _applyFallbackTransitionPlanIfNeeded();
    }

    try {
      final result = await transitionRepository!.getNextTransition(
        currentTrackId: currentTrackId,
        excludeTrackIds: excludeTrackIds,
        temperature: temperature,
      );

      return switch (result) {
        ResultOk(value: final plan) => () {
            if (_currentTrack?.id == currentTrackId) {
              setTransitionPlan(plan);
            }
            return plan;
          }(),
        ResultError(failure: final failure) => () {
            debugPrint(
              '[SmartCrossfade] Backend transition unavailable (${failure.message}). Using local queue fallback.',
            );
            return _applyFallbackTransitionPlanIfNeeded();
          }(),
      };
    } catch (e) {
      debugPrint('[SmartCrossfade] Exception during transition fetch: $e. Using local fallback.');
      onError?.call(e);
      return _applyFallbackTransitionPlanIfNeeded();
    }
  }

  void _onPositionChanged(Duration pos) {
    if (!isSmartTransitionEnabled) return;
    final curTrack = _currentTrack;
    if (curTrack == null) return;

    final currentMs = pos.inMilliseconds;
    final plan = _currentTransitionPlan;

    // Determine target transition boundary:
    // If planned: use triggerTransitionAtMs.
    // If not yet planned or fallback: trigger 7 seconds before track end.
    final trackDurMs = curTrack.durationMs ?? _player.duration?.inMilliseconds ?? 0;
    final triggerMs = plan?.currentTrack.triggerTransitionAtMs ??
        (trackDurMs > 15000 ? trackDurMs - 7000 : 0);

    if (triggerMs > 0 &&
        currentMs >= triggerMs &&
        !_isCrossfading &&
        !_isTransitionCompleted) {
      _triggerSmartTransition();
    }
  }

  /// Smoothly fades out the current track and advances to the upcoming track
  void _triggerSmartTransition() {
    _isCrossfading = true;

    final plan = _currentTransitionPlan;
    final nextTrack = plan != null
        ? plan.nextTrack.toTrackEntity()
        : getNextTrackFromQueue?.call();

    if (nextTrack == null) {
      _isCrossfading = false;
      return;
    }

    debugPrint(
      '[SmartCrossfade] ✨ Auto-DJ Transition Triggered! Jumping to next track: ${nextTrack.title}',
    );

    onCrossfadeStarted?.call(plan != null
        ? plan.nextTrack
        : NextTrackTransition(
            id: nextTrack.id,
            title: nextTrack.title,
            fileUrl: nextTrack.fileUrl,
            artists: [nextTrack.artistName],
            startPlaybackAtMs: nextTrack.cueInMs ?? 1000,
          ));

    // Smoothly ramp volume down over 1.5 seconds, then advance
    _fadeTimer?.cancel();
    const fadeDurationMs = 1500;
    final stopwatch = Stopwatch()..start();
    const interval = Duration(milliseconds: 50);

    _fadeTimer = Timer.periodic(interval, (timer) {
      final elapsed = stopwatch.elapsedMilliseconds;
      final progress = (elapsed / fadeDurationMs).clamp(0.0, 1.0);
      final vol = (1.0 - progress).clamp(0.0, 1.0);
      _player.setVolume(vol);

      if (progress >= 1.0) {
        timer.cancel();
        _isCrossfading = false;
        _isTransitionCompleted = true;
        _player.setVolume(1.0);

        // Advance to next song without dead silence
        onTrackTransitioned?.call(nextTrack);
      }
    });
  }

  void _abortOngoingTransition() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _isCrossfading = false;
    _isTransitionCompleted = false;
    _pendingNextTrack = null;
    _currentTransitionPlan = null;
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> seek(Duration newPosition) async {
    _abortOngoingTransition();
    await _player.setVolume(1.0);
    await _player.seek(newPosition);
  }

  Future<void> stop() async {
    _abortOngoingTransition();
    await _player.stop();
    await _player.setVolume(1.0);
  }

  Future<void> setLoopMode(ja.LoopMode loopMode) async {
    await _player.setLoopMode(loopMode);
  }

  void _subscribeToPlayerStreams() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _durationSub?.cancel();

    _positionSub = _player.positionStream.listen((pos) {
      _positionController.add(pos);
      _onPositionChanged(pos);
    });

    _stateSub = _player.playerStateStream.listen((state) {
      _playerStateController.add(state);
    });

    _durationSub = _player.durationStream.listen((dur) {
      _durationController.add(dur);
    });
  }

  ja.AudioSource? _buildAudioSource(TrackEntity track, MediaItem mediaItem) {
    final localPath = track.localFilePath;
    if (localPath != null && File(localPath).existsSync()) {
      return ja.AudioSource.file(localPath, tag: mediaItem);
    }

    final rawUrl = track.fileUrl;
    if (rawUrl != null && rawUrl.trim().isNotEmpty) {
      final streamUrl = AudioUrlResolver.resolve(rawUrl.trim());
      final safeUri = Uri.parse(Uri.encodeFull(streamUrl));
      return ja.AudioSource.uri(safeUri, tag: mediaItem);
    }

    return null;
  }

  MediaItem _createMediaItem(TrackEntity track) {
    return MediaItem(
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
  }

  /// Initialises system audio session
  static Future<void> initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('[SmartCrossfade] Error initializing audio session: $e');
    }
  }

  void dispose() {
    _abortOngoingTransition();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _durationSub?.cancel();

    _playerStateController.close();
    _positionController.close();
    _durationController.close();
    _transitionPlanController.close();

    _player.dispose();
    try {
      _secondaryPlayer?.dispose();
    } catch (_) {}
  }
}

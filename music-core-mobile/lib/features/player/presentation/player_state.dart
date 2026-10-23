import 'package:just_audio/just_audio.dart';
import 'package:meta/meta.dart';
import '../../catalog/domain/entities/track_entity.dart';
import '../domain/entities/transition_plan.dart';

@immutable
class PlayerState {
  const PlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.currentIndex = 0,
    this.isShuffle = false,
    this.loopMode = LoopMode.off,
    this.isCrossfading = false,
    this.currentTransitionPlan,
  });

  final TrackEntity? currentTrack;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final List<TrackEntity> queue;
  final int currentIndex;
  final bool isShuffle;
  final LoopMode loopMode;
  final bool isCrossfading;
  final AutoDjTransitionResponse? currentTransitionPlan;

  bool get hasTrack => currentTrack != null;
  bool get hasNext => queue.isNotEmpty && currentIndex < queue.length - 1;
  bool get hasPrevious => queue.isNotEmpty && currentIndex > 0;

  PlayerState copyWith({
    TrackEntity? currentTrack,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    List<TrackEntity>? queue,
    int? currentIndex,
    bool? isShuffle,
    LoopMode? loopMode,
    bool? isCrossfading,
    AutoDjTransitionResponse? currentTransitionPlan,
    bool clearTrack = false,
    bool clearTransitionPlan = false,
  }) {
    return PlayerState(
      currentTrack: clearTrack ? null : (currentTrack ?? this.currentTrack),
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffle: isShuffle ?? this.isShuffle,
      loopMode: loopMode ?? this.loopMode,
      isCrossfading: isCrossfading ?? this.isCrossfading,
      currentTransitionPlan: clearTransitionPlan
          ? null
          : (currentTransitionPlan ?? this.currentTransitionPlan),
    );
  }
}

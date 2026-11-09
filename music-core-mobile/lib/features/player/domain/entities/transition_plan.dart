import 'dart:math' as math;
import 'package:meta/meta.dart';
import '../../../catalog/domain/entities/track_entity.dart';

/// Information regarding the currently playing track's transition boundaries.
@immutable
class CurrentTrackTransition {
  const CurrentTrackTransition({
    required this.id,
    this.title,
    this.durationMs,
    this.bpm,
    this.camelotKey,
    this.loudnessLufs,
    required this.triggerTransitionAtMs,
    required this.stopPlaybackAtMs,
  });

  final String id;
  final String? title;
  final int? durationMs;
  final double? bpm;
  final String? camelotKey;
  final double? loudnessLufs;
  final int triggerTransitionAtMs;
  final int stopPlaybackAtMs;

  factory CurrentTrackTransition.fromJson(Map<String, dynamic> json) {
    return CurrentTrackTransition(
      id: json['id'] as String? ?? '',
      title: json['title'] as String?,
      durationMs: (json['durationMs'] ?? json['duration_ms']) as int?,
      bpm: (json['bpm'] as num?)?.toDouble(),
      camelotKey: (json['camelotKey'] ?? json['camelot_key']) as String?,
      loudnessLufs:
          ((json['loudnessLufs'] ?? json['loudness_lufs']) as num?)?.toDouble(),
      triggerTransitionAtMs: (json['triggerTransitionAtMs'] ??
              json['trigger_transition_at_ms'] ??
              0) as int,
      stopPlaybackAtMs:
          (json['stopPlaybackAtMs'] ?? json['stop_playback_at_ms'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (title != null) 'title': title,
        if (durationMs != null) 'durationMs': durationMs,
        if (bpm != null) 'bpm': bpm,
        if (camelotKey != null) 'camelotKey': camelotKey,
        if (loudnessLufs != null) 'loudnessLufs': loudnessLufs,
        'triggerTransitionAtMs': triggerTransitionAtMs,
        'stopPlaybackAtMs': stopPlaybackAtMs,
      };

  CurrentTrackTransition copyWith({
    String? id,
    String? title,
    int? durationMs,
    double? bpm,
    String? camelotKey,
    double? loudnessLufs,
    int? triggerTransitionAtMs,
    int? stopPlaybackAtMs,
  }) {
    return CurrentTrackTransition(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMs: durationMs ?? this.durationMs,
      bpm: bpm ?? this.bpm,
      camelotKey: camelotKey ?? this.camelotKey,
      loudnessLufs: loudnessLufs ?? this.loudnessLufs,
      triggerTransitionAtMs:
          triggerTransitionAtMs ?? this.triggerTransitionAtMs,
      stopPlaybackAtMs: stopPlaybackAtMs ?? this.stopPlaybackAtMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrentTrackTransition &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          triggerTransitionAtMs == other.triggerTransitionAtMs &&
          stopPlaybackAtMs == other.stopPlaybackAtMs;

  @override
  int get hashCode => Object.hash(id, triggerTransitionAtMs, stopPlaybackAtMs);
}

/// Metadata and playback cue points for the upcoming track in a seamless transition.
@immutable
class NextTrackTransition {
  const NextTrackTransition({
    required this.id,
    required this.title,
    this.fileUrl,
    this.coverImageUrl,
    this.artists = const [],
    this.durationMs,
    this.bpm,
    this.camelotKey,
    required this.startPlaybackAtMs,
    this.targetDownbeatMs,
  });

  final String id;
  final String title;
  final String? fileUrl;
  final String? coverImageUrl;
  final List<String> artists;
  final int? durationMs;
  final double? bpm;
  final String? camelotKey;
  final int startPlaybackAtMs;
  final int? targetDownbeatMs;

  factory NextTrackTransition.fromJson(Map<String, dynamic> json) {
    List<String> parsedArtists = const [];
    if (json['artists'] is List) {
      parsedArtists = (json['artists'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json['artist'] is String) {
      parsedArtists = [json['artist'] as String];
    } else if (json['artistName'] is String) {
      parsedArtists = [json['artistName'] as String];
    }

    return NextTrackTransition(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Chưa có tiêu đề',
      fileUrl: (json['fileUrl'] ?? json['file_url']) as String?,
      coverImageUrl:
          (json['coverImageUrl'] ?? json['cover_image_url']) as String?,
      artists: parsedArtists,
      durationMs: (json['durationMs'] ?? json['duration_ms']) as int?,
      bpm: (json['bpm'] as num?)?.toDouble(),
      camelotKey: (json['camelotKey'] ?? json['camelot_key']) as String?,
      startPlaybackAtMs: (json['startPlaybackAtMs'] ??
              json['start_playback_at_ms'] ??
              0) as int,
      targetDownbeatMs:
          (json['targetDownbeatMs'] ?? json['target_downbeat_ms']) as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
        'artists': artists,
        if (durationMs != null) 'durationMs': durationMs,
        if (bpm != null) 'bpm': bpm,
        if (camelotKey != null) 'camelotKey': camelotKey,
        'startPlaybackAtMs': startPlaybackAtMs,
        if (targetDownbeatMs != null) 'targetDownbeatMs': targetDownbeatMs,
      };

  /// Converts this transition payload into standard [TrackEntity] for player UI display.
  TrackEntity toTrackEntity() {
    return TrackEntity(
      id: id,
      title: title,
      artistName: artists.isNotEmpty ? artists.join(', ') : 'Nghệ sĩ chưa rõ',
      coverImageUrl: coverImageUrl,
      fileUrl: fileUrl,
      durationMs: durationMs,
    );
  }

  NextTrackTransition copyWith({
    String? id,
    String? title,
    String? fileUrl,
    String? coverImageUrl,
    List<String>? artists,
    int? durationMs,
    double? bpm,
    String? camelotKey,
    int? startPlaybackAtMs,
    int? targetDownbeatMs,
  }) {
    return NextTrackTransition(
      id: id ?? this.id,
      title: title ?? this.title,
      fileUrl: fileUrl ?? this.fileUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      artists: artists ?? this.artists,
      durationMs: durationMs ?? this.durationMs,
      bpm: bpm ?? this.bpm,
      camelotKey: camelotKey ?? this.camelotKey,
      startPlaybackAtMs: startPlaybackAtMs ?? this.startPlaybackAtMs,
      targetDownbeatMs: targetDownbeatMs ?? this.targetDownbeatMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NextTrackTransition &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          startPlaybackAtMs == other.startPlaybackAtMs;

  @override
  int get hashCode => Object.hash(id, startPlaybackAtMs);
}

/// Specifications for crossfading parameters, timing, and volume balance.
@immutable
class TransitionPlan {
  const TransitionPlan({
    required this.transitionType,
    required this.crossfadeDurationMs,
    required this.preBufferAtMs,
    required this.volumeBalanceGainDb,
    this.tempoRatio,
    this.compatibilityScore,
  });

  final String transitionType;
  final int crossfadeDurationMs;
  final int preBufferAtMs;
  final double volumeBalanceGainDb;
  final double? tempoRatio;
  final double? compatibilityScore;

  /// Linear gain factor derived from decibels: 10^(dB / 20) clamped to [0.0, 1.0].
  double get linearGainMultiplier {
    final gain = math.pow(10.0, volumeBalanceGainDb / 20.0).toDouble();
    return gain.clamp(0.0, 1.0);
  }

  factory TransitionPlan.fromJson(Map<String, dynamic> json) {
    return TransitionPlan(
      transitionType: (json['transitionType'] ??
              json['transition_type'] ??
              'BEAT_CROSSFADE') as String,
      crossfadeDurationMs: (json['crossfadeDurationMs'] ??
              json['crossfade_duration_ms'] ??
              8000) as int,
      preBufferAtMs:
          (json['preBufferAtMs'] ?? json['pre_buffer_at_ms'] ?? 0) as int,
      volumeBalanceGainDb: ((json['volumeBalanceGainDb'] ??
                  json['volume_balance_gain_db'] ??
                  0.0) as num)
              .toDouble(),
      tempoRatio: ((json['tempoRatio'] ?? json['tempo_ratio']) as num?)?.toDouble(),
      compatibilityScore: ((json['compatibilityScore'] ??
              json['compatibility_score']) as num?)
          ?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'transitionType': transitionType,
        'crossfadeDurationMs': crossfadeDurationMs,
        'preBufferAtMs': preBufferAtMs,
        'volumeBalanceGainDb': volumeBalanceGainDb,
        if (tempoRatio != null) 'tempoRatio': tempoRatio,
        if (compatibilityScore != null) 'compatibilityScore': compatibilityScore,
      };

  TransitionPlan copyWith({
    String? transitionType,
    int? crossfadeDurationMs,
    int? preBufferAtMs,
    double? volumeBalanceGainDb,
    double? tempoRatio,
    double? compatibilityScore,
  }) {
    return TransitionPlan(
      transitionType: transitionType ?? this.transitionType,
      crossfadeDurationMs: crossfadeDurationMs ?? this.crossfadeDurationMs,
      preBufferAtMs: preBufferAtMs ?? this.preBufferAtMs,
      volumeBalanceGainDb: volumeBalanceGainDb ?? this.volumeBalanceGainDb,
      tempoRatio: tempoRatio ?? this.tempoRatio,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransitionPlan &&
          runtimeType == other.runtimeType &&
          transitionType == other.transitionType &&
          crossfadeDurationMs == other.crossfadeDurationMs &&
          preBufferAtMs == other.preBufferAtMs &&
          volumeBalanceGainDb == other.volumeBalanceGainDb;

  @override
  int get hashCode => Object.hash(
        transitionType,
        crossfadeDurationMs,
        preBufferAtMs,
        volumeBalanceGainDb,
      );
}

/// Complete response from GET /api/v1/catalog/transitions/next.
@immutable
class AutoDjTransitionResponse {
  const AutoDjTransitionResponse({
    required this.currentTrack,
    required this.nextTrack,
    required this.transitionPlan,
  });

  final CurrentTrackTransition currentTrack;
  final NextTrackTransition nextTrack;
  final TransitionPlan transitionPlan;

  factory AutoDjTransitionResponse.fromJson(Map<String, dynamic> json) {
    final currentTrackMap =
        json['currentTrack'] ?? json['current_track'] ?? const <String, dynamic>{};
    final nextTrackMap =
        json['nextTrack'] ?? json['next_track'] ?? const <String, dynamic>{};
    final transitionPlanMap =
        json['transitionPlan'] ?? json['transition_plan'] ?? const <String, dynamic>{};

    return AutoDjTransitionResponse(
      currentTrack: CurrentTrackTransition.fromJson(
        Map<String, dynamic>.from(currentTrackMap as Map),
      ),
      nextTrack: NextTrackTransition.fromJson(
        Map<String, dynamic>.from(nextTrackMap as Map),
      ),
      transitionPlan: TransitionPlan.fromJson(
        Map<String, dynamic>.from(transitionPlanMap as Map),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'currentTrack': currentTrack.toJson(),
        'nextTrack': nextTrack.toJson(),
        'transitionPlan': transitionPlan.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutoDjTransitionResponse &&
          runtimeType == other.runtimeType &&
          currentTrack == other.currentTrack &&
          nextTrack == other.nextTrack &&
          transitionPlan == other.transitionPlan;

  @override
  int get hashCode => Object.hash(currentTrack, nextTrack, transitionPlan);
}

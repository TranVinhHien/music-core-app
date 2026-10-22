import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/client_event.dart';
import '../domain/repositories/event_sync_repository.dart';

class EventTracker {
  EventTracker({
    required EventSyncRepository repository,
    String? Function()? sessionIdProvider,
    Duration syncInterval = const Duration(minutes: 1),
    bool autoStartSync = true,
  })  : _repository = repository,
        _sessionIdProvider = sessionIdProvider,
        _syncInterval = syncInterval {
    if (autoStartSync) {
      startSyncTimer();
    }
  }

  final EventSyncRepository _repository;
  final String? Function()? _sessionIdProvider;
  final Duration _syncInterval;
  final _uuid = const Uuid();

  Timer? _timer;
  bool _isSyncing = false;

  void startSyncTimer() {
    _timer?.cancel();
    // Schedule periodic 1-minute outbox sync
    _timer = Timer.periodic(_syncInterval, (_) => syncPendingEvents());
    // Also perform initial flush attempt in background
    unawaited(syncPendingEvents());
  }

  void stopSyncTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stopSyncTimer();
  }

  Future<void> syncPendingEvents() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await _repository.syncPendingEvents(maxBatch: 100);
    } catch (e) {
      debugPrint('[EventTracker] Outbox sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  String? _activeSessionId;

  String _resolveSessionId(String? sessionId) {
    if (sessionId != null && sessionId.trim().isNotEmpty) {
      _activeSessionId = sessionId.trim();
      return _activeSessionId!;
    }
    final candidate = _sessionIdProvider?.call();
    if (candidate != null && candidate.trim().isNotEmpty) {
      _activeSessionId = candidate.trim();
      return _activeSessionId!;
    }
    if (_activeSessionId != null && _activeSessionId!.isNotEmpty) {
      return _activeSessionId!;
    }
    // Fallback: Generate a valid UUID so playback events always satisfy schema
    _activeSessionId = _uuid.v4();
    return _activeSessionId!;
  }

  // ===========================================================================
  // 1. Playback Events
  // ===========================================================================

  Future<void> trackStarted({
    required String trackId,
    required int durationMs,
    int positionMs = 0,
    String? sessionId,
    EventSourceModel? source,
  }) async {
    final effectiveSessionId = _resolveSessionId(sessionId);
    await _repository.recordEvent(
      ClientEvent(
        eventId: _uuid.v4(),
        eventType: 'TRACK_STARTED',
        occurredAt: DateTime.now().toUtc(),
        sessionId: effectiveSessionId.isNotEmpty ? effectiveSessionId : null,
        trackId: trackId,
        source: source,
        properties: {
          'duration_ms': durationMs < 0 ? 0 : durationMs,
          'position_ms': positionMs < 0 ? 0 : positionMs,
        },
      ),
    );
  }

  Future<void> trackCompleted({
    required String trackId,
    required int durationMs,
    required int listenedMs,
    String? sessionId,
    EventSourceModel? source,
  }) async {
    final effectiveSessionId = _resolveSessionId(sessionId);
    await _repository.recordEvent(
      ClientEvent(
        eventId: _uuid.v4(),
        eventType: 'TRACK_COMPLETED',
        occurredAt: DateTime.now().toUtc(),
        sessionId: effectiveSessionId.isNotEmpty ? effectiveSessionId : null,
        trackId: trackId,
        source: source,
        properties: {
          'duration_ms': durationMs < 0 ? 0 : durationMs,
          'listened_ms': listenedMs < 0 ? 0 : listenedMs,
        },
      ),
    );
  }

  Future<void> trackSkipped({
    required String trackId,
    required int durationMs,
    required int positionMs,
    required int listenedMs,
    String? nextTrackId,
    String? sessionId,
    EventSourceModel? source,
  }) async {
    final effectiveSessionId = _resolveSessionId(sessionId);
    final props = <String, dynamic>{
      'duration_ms': durationMs < 0 ? 0 : durationMs,
      'position_ms': positionMs < 0 ? 0 : positionMs,
      'listened_ms': listenedMs < 0 ? 0 : listenedMs,
    };
    if (nextTrackId != null && nextTrackId.isNotEmpty) {
      props['next_track_id'] = nextTrackId;
    }

    await _repository.recordEvent(
      ClientEvent(
        eventId: _uuid.v4(),
        eventType: 'TRACK_SKIPPED',
        occurredAt: DateTime.now().toUtc(),
        sessionId: effectiveSessionId.isNotEmpty ? effectiveSessionId : null,
        trackId: trackId,
        source: source,
        properties: props,
      ),
    );
  }

  Future<void> trackPaused({
    required String trackId,
    required int positionMs,
    required int listenedMs,
    String? sessionId,
    EventSourceModel? source,
  }) async {
    final effectiveSessionId = _resolveSessionId(sessionId);
    await _repository.recordEvent(
      ClientEvent(
        eventId: _uuid.v4(),
        eventType: 'TRACK_PAUSED',
        occurredAt: DateTime.now().toUtc(),
        sessionId: effectiveSessionId.isNotEmpty ? effectiveSessionId : null,
        trackId: trackId,
        source: source,
        properties: {
          'position_ms': positionMs < 0 ? 0 : positionMs,
          'listened_ms': listenedMs < 0 ? 0 : listenedMs,
        },
      ),
    );
  }

  Future<void> trackSeeked({
    required String trackId,
    required int fromPositionMs,
    required int toPositionMs,
    String? sessionId,
    EventSourceModel? source,
  }) async {
    final effectiveSessionId = _resolveSessionId(sessionId);
    await _repository.recordEvent(
      ClientEvent(
        eventId: _uuid.v4(),
        eventType: 'TRACK_SEEKED',
        occurredAt: DateTime.now().toUtc(),
        sessionId: effectiveSessionId.isNotEmpty ? effectiveSessionId : null,
        trackId: trackId,
        source: source,
        properties: {
          'from_position_ms': fromPositionMs < 0 ? 0 : fromPositionMs,
          'to_position_ms': toPositionMs < 0 ? 0 : toPositionMs,
        },
      ),
    );
  }

  Future<void> trackReplayed({
    required String trackId,
    required int positionMs,
    String? sessionId,
    EventSourceModel? source,
  }) async {
    final effectiveSessionId = _resolveSessionId(sessionId);
    await _repository.recordEvent(
      ClientEvent(
        eventId: _uuid.v4(),
        eventType: 'TRACK_REPLAYED',
        occurredAt: DateTime.now().toUtc(),
        sessionId: effectiveSessionId.isNotEmpty ? effectiveSessionId : null,
        trackId: trackId,
        source: source,
        properties: {
          'position_ms': positionMs < 0 ? 0 : positionMs,
          'replay_type': 'MANUAL_REPLAY',
        },
      ),
    );
  }

  // ===========================================================================
  // 2. Discovery & Search Events
  // ===========================================================================

  Future<void> searchPerformed({
    required String query,
    String searchType = 'track',
    int? resultsCount,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final props = <String, dynamic>{
      'query': trimmed,
      'search_type': searchType,
    };
    if (resultsCount != null && resultsCount >= 0) {
      props['results_count'] = resultsCount;
    }

    await _repository.recordEvent(
      ClientEvent(
        eventId: _uuid.v4(),
        eventType: 'SEARCH_PERFORMED',
        occurredAt: DateTime.now().toUtc(),
        properties: props,
      ),
    );
  }

  // ===========================================================================
  // 3. Library & Playlist Events
  // ===========================================================================

  Future<void> trackFavorited({required String trackId}) async {
    await _repository.recordEvent(
      ClientEvent(
        eventId: _uuid.v4(),
        eventType: 'TRACK_FAVORITED',
        occurredAt: DateTime.now().toUtc(),
        trackId: trackId,
        properties: const {},
      ),
    );
  }

  Future<void> trackUnfavorited({required String trackId}) async {
    await _repository.recordEvent(
      ClientEvent(
        eventId: _uuid.v4(),
        eventType: 'TRACK_UNFAVORITED',
        occurredAt: DateTime.now().toUtc(),
        trackId: trackId,
        properties: const {},
      ),
    );
  }

  Future<void> trackAddedToPlaylist({
    required String trackId,
    required String playlistId,
    int? position,
  }) async {
    final props = <String, dynamic>{
      'playlist_id': playlistId,
    };
    if (position != null && position >= 0) {
      props['position'] = position;
    }

    await _repository.recordEvent(
      ClientEvent(
        eventId: _uuid.v4(),
        eventType: 'TRACK_ADDED_TO_PLAYLIST',
        occurredAt: DateTime.now().toUtc(),
        trackId: trackId,
        properties: props,
      ),
    );
  }

  Future<void> trackRemovedFromPlaylist({
    required String trackId,
    required String playlistId,
  }) async {
    await _repository.recordEvent(
      ClientEvent(
        eventId: _uuid.v4(),
        eventType: 'TRACK_REMOVED_FROM_PLAYLIST',
        occurredAt: DateTime.now().toUtc(),
        trackId: trackId,
        properties: {
          'playlist_id': playlistId,
        },
      ),
    );
  }

  Future<void> playlistPlayed({
    required String playlistId,
    int? trackCount,
    String playbackMode = 'SEQUENTIAL',
  }) async {
    final props = <String, dynamic>{
      'playlist_id': playlistId,
      'playback_mode': playbackMode,
    };
    if (trackCount != null && trackCount >= 0) {
      props['track_count'] = trackCount;
    }

    await _repository.recordEvent(
      ClientEvent(
        eventId: _uuid.v4(),
        eventType: 'PLAYLIST_PLAYED',
        occurredAt: DateTime.now().toUtc(),
        properties: props,
      ),
    );
  }
}

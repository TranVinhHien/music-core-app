import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/music_database.dart';
import '../../../../core/result.dart';
import '../../domain/entities/client_event.dart';
import '../../domain/repositories/event_sync_repository.dart';
import '../datasources/events_remote_data_source.dart';

class EventSyncRepositoryImpl implements EventSyncRepository {
  EventSyncRepositoryImpl({
    required MusicDatabase db,
    required EventsRemoteDataSource remoteDataSource,
    Future<bool> Function()? isOnlineChecker,
    String? Function()? sessionIdProvider,
  })  : _db = db,
        _remoteDataSource = remoteDataSource,
        _isOnlineChecker = isOnlineChecker,
        _sessionIdProvider = sessionIdProvider;

  final MusicDatabase _db;
  final EventsRemoteDataSource _remoteDataSource;
  final Future<bool> Function()? _isOnlineChecker;
  final String? Function()? _sessionIdProvider;
  final _uuid = const Uuid();

  Future<bool> _isOnline() async {
    if (_isOnlineChecker != null) {
      return _isOnlineChecker!();
    }
    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> recordEvent(ClientEvent event) async {
    try {
      final propertiesStr = jsonEncode(event.properties);
      final sourceStr =
          event.source != null ? jsonEncode(event.source!.toJson()) : null;

      await _db.insertPendingEvent(
        PendingEventsCompanion(
          eventId: Value(event.eventId),
          eventType: Value(event.eventType),
          occurredAt: Value(event.occurredAt),
          sessionId: Value(event.sessionId),
          trackId: Value(event.trackId),
          sourceJson: Value(sourceStr),
          propertiesJson: Value(propertiesStr),
          schemaVersion: Value(event.schemaVersion),
        ),
      );
    } catch (e) {
      _logRaw('[EventSync] Failed to record event ${event.eventId}: $e');
    }
  }

  @override
  Future<Result<int>> syncPendingEvents({int maxBatch = 100}) async {
    final online = await _isOnline();
    if (!online) {
      _logRaw('[EventSync] Offline. Will retry on next 1-minute cycle.');
      return const ResultOk(0);
    }

    final rows = await _db.getPendingEvents(limit: maxBatch);
    if (rows.isEmpty) {
      return const ResultOk(0);
    }

    final clientEvents = <ClientEvent>[];
    for (final row in rows) {
      Map<String, dynamic> props = {};
      try {
        props = jsonDecode(row.propertiesJson) as Map<String, dynamic>;
      } catch (_) {}

      EventSourceModel? source;
      if (row.sourceJson != null && row.sourceJson!.isNotEmpty) {
        try {
          final sourceMap =
              jsonDecode(row.sourceJson!) as Map<String, dynamic>;
          source = EventSourceModel.fromJson(sourceMap);
        } catch (_) {}
      }

      // Auto-heal legacy or missing session_id for playback events
      var effectiveSessionId = row.sessionId;
      final isPlaybackEvent = row.eventType.startsWith('TRACK_') &&
          row.eventType != 'TRACK_FAVORITED' &&
          row.eventType != 'TRACK_UNFAVORITED' &&
          row.eventType != 'TRACK_ADDED_TO_PLAYLIST' &&
          row.eventType != 'TRACK_REMOVED_FROM_PLAYLIST';

      if (isPlaybackEvent &&
          (effectiveSessionId == null || effectiveSessionId.trim().isEmpty)) {
        final candidate = _sessionIdProvider?.call();
        effectiveSessionId = (candidate != null && candidate.trim().isNotEmpty)
            ? candidate.trim()
            : _uuid.v4();
      }

      clientEvents.add(
        ClientEvent(
          eventId: row.eventId,
          eventType: row.eventType,
          occurredAt: row.occurredAt,
          sessionId: effectiveSessionId,
          trackId: row.trackId,
          source: source,
          properties: props,
          schemaVersion: row.schemaVersion,
        ),
      );
    }

    final result = await _remoteDataSource.sendEventBatch(clientEvents);
    switch (result) {
      case ResultOk(value: final processedIds):
        final idsToDelete = processedIds.isNotEmpty
            ? processedIds
            : clientEvents.map((ClientEvent e) => e.eventId).toList();
        final deletedCount = await _db.deletePendingEvents(idsToDelete);
        _logRaw(
            '[EventSync] Successfully sent and removed $deletedCount events.');
        return ResultOk(deletedCount);

      case ResultError(failure: final failure):
        if (failure is ValidationFailure) {
          // If the server rejected with 400 ValidationFailure, discard the unrecoverable
          // records from local DB so they do not block the queue in an infinite loop.
          final idsToDelete =
              clientEvents.map((ClientEvent e) => e.eventId).toList();
          await _db.deletePendingEvents(idsToDelete);
          _logRaw(
              '[EventSync] 400 Validation Failure from backend: ${failure.message}. '
              'Removed ${idsToDelete.length} unprocessable events from local DB.');
          return ResultError(failure);
        }
        _logRaw(
            '[EventSync] Failed to send event batch: $failure. Events kept in local DB.');
        return ResultError(failure);
    }
  }

  void _logRaw(String text) {
    print(text);
  }

  @override
  Future<int> getPendingEventCount() async {
    return _db.countPendingEvents();
  }
}

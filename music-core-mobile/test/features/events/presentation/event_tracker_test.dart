import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/events/domain/entities/client_event.dart';
import 'package:flutter_clean_architecture_example/features/events/domain/repositories/event_sync_repository.dart';
import 'package:flutter_clean_architecture_example/features/events/presentation/event_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeEventSyncRepository implements EventSyncRepository {
  final List<ClientEvent> recordedEvents = [];
  int syncCallCount = 0;

  @override
  Future<Result<void>> recordEvent(ClientEvent event) async {
    recordedEvents.add(event);
    return const ResultOk(null);
  }

  @override
  Future<Result<int>> syncPendingEvents({int maxBatch = 100}) async {
    syncCallCount++;
    return ResultOk(recordedEvents.length);
  }

  @override
  Future<int> getPendingEventCount() async => recordedEvents.length;
}

void main() {
  late FakeEventSyncRepository repository;
  late EventTracker tracker;

  setUp(() {
    repository = FakeEventSyncRepository();
    tracker = EventTracker(
      repository: repository,
      sessionIdProvider: () => 'sess_uuid_999',
      syncInterval: const Duration(seconds: 1),
      autoStartSync: false,
    );
  });

  tearDown(() {
    tracker.dispose();
  });

  group('EventTracker', () {
    test('trackStarted creates valid TRACK_STARTED event with session_id and source', () async {
      await tracker.trackStarted(
        trackId: 'trk_01',
        durationMs: 240000,
        positionMs: 0,
        source: const EventSourceModel(type: 'playlist', id: 'pl_1'),
      );

      expect(repository.recordedEvents.length, equals(1));
      final event = repository.recordedEvents.first;
      expect(event.eventType, equals('TRACK_STARTED'));
      expect(event.sessionId, equals('sess_uuid_999'));
      expect(event.trackId, equals('trk_01'));
      expect(event.properties['duration_ms'], equals(240000));
      expect(event.source?.toJson(), equals({'type': 'playlist', 'id': 'pl_1'}));
    });

    test('trackCompleted creates valid TRACK_COMPLETED event', () async {
      await tracker.trackCompleted(
        trackId: 'trk_01',
        durationMs: 240000,
        listenedMs: 240000,
      );

      final event = repository.recordedEvents.last;
      expect(event.eventType, equals('TRACK_COMPLETED'));
      expect(event.trackId, equals('trk_01'));
      expect(event.properties['listened_ms'], equals(240000));
      expect(event.properties['duration_ms'], equals(240000));
    });

    test('trackSkipped creates valid TRACK_SKIPPED event', () async {
      await tracker.trackSkipped(
        trackId: 'trk_02',
        durationMs: 200000,
        positionMs: 45000,
        listenedMs: 45000,
        nextTrackId: 'trk_03',
      );

      final event = repository.recordedEvents.last;
      expect(event.eventType, equals('TRACK_SKIPPED'));
      expect(event.trackId, equals('trk_02'));
      expect(event.properties['next_track_id'], equals('trk_03'));
      expect(event.properties['position_ms'], equals(45000));
    });

    test('trackPaused creates valid TRACK_PAUSED event', () async {
      await tracker.trackPaused(
        trackId: 'trk_03',
        positionMs: 12000,
        listenedMs: 12000,
      );

      final event = repository.recordedEvents.last;
      expect(event.eventType, equals('TRACK_PAUSED'));
      expect(event.properties['position_ms'], equals(12000));
    });

    test('trackSeeked creates valid TRACK_SEEKED event', () async {
      await tracker.trackSeeked(
        trackId: 'trk_04',
        fromPositionMs: 10000,
        toPositionMs: 50000,
      );

      final event = repository.recordedEvents.last;
      expect(event.eventType, equals('TRACK_SEEKED'));
      expect(event.properties['from_position_ms'], equals(10000));
      expect(event.properties['to_position_ms'], equals(50000));
    });

    test('trackReplayed creates valid TRACK_REPLAYED event', () async {
      await tracker.trackReplayed(
        trackId: 'trk_05',
        positionMs: 25000,
      );

      final event = repository.recordedEvents.last;
      expect(event.eventType, equals('TRACK_REPLAYED'));
      expect(event.trackId, equals('trk_05'));
      expect(event.properties['position_ms'], equals(25000));
    });

    test('searchPerformed creates valid SEARCH_PERFORMED event', () async {
      await tracker.searchPerformed(
        query: 'sơn tùng',
        resultsCount: 15,
      );

      final event = repository.recordedEvents.last;
      expect(event.eventType, equals('SEARCH_PERFORMED'));
      expect(event.properties['query'], equals('sơn tùng'));
      expect(event.properties['results_count'], equals(15));
    });

    test('trackFavorited and trackUnfavorited create valid events', () async {
      await tracker.trackFavorited(trackId: 'trk_06');
      expect(repository.recordedEvents.last.eventType, equals('TRACK_FAVORITED'));

      await tracker.trackUnfavorited(trackId: 'trk_06');
      expect(repository.recordedEvents.last.eventType, equals('TRACK_UNFAVORITED'));
    });

    test('trackAddedToPlaylist and trackRemovedFromPlaylist create valid events', () async {
      await tracker.trackAddedToPlaylist(trackId: 'trk_07', playlistId: 'pl_07');
      expect(repository.recordedEvents.last.eventType, equals('TRACK_ADDED_TO_PLAYLIST'));
      expect(repository.recordedEvents.last.properties['playlist_id'], equals('pl_07'));

      await tracker.trackRemovedFromPlaylist(trackId: 'trk_07', playlistId: 'pl_07');
      expect(repository.recordedEvents.last.eventType, equals('TRACK_REMOVED_FROM_PLAYLIST'));
    });

    test('playlistPlayed creates valid PLAYLIST_PLAYED event', () async {
      await tracker.playlistPlayed(playlistId: 'pl_08', trackCount: 20);

      final event = repository.recordedEvents.last;
      expect(event.eventType, equals('PLAYLIST_PLAYED'));
      expect(event.properties['playlist_id'], equals('pl_08'));
      expect(event.properties['track_count'], equals(20));
    });
  });
}

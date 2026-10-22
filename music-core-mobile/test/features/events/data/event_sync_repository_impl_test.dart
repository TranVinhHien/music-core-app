import 'package:flutter_clean_architecture_example/core/database/music_database.dart';
import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/events/data/datasources/events_remote_data_source.dart';
import 'package:flutter_clean_architecture_example/features/events/data/repositories/event_sync_repository_impl.dart';
import 'package:flutter_clean_architecture_example/features/events/domain/entities/client_event.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeEventsRemoteDataSource implements EventsRemoteDataSource {
  final List<List<ClientEvent>> sentBatches = [];
  bool shouldFail = false;

  @override
  Future<Result<List<String>>> sendEventBatch(List<ClientEvent> events) async {
    if (shouldFail) {
      return const ResultError(ServerFailure('Server 500 error'));
    }
    sentBatches.add(events);
    return ResultOk(events.map((e) => e.eventId).toList());
  }
}

void main() {
  late MusicDatabase database;
  late FakeEventsRemoteDataSource remoteDataSource;
  bool isOnline = true;
  late EventSyncRepositoryImpl repository;

  setUp(() {
    database = MusicDatabase.forTesting();
    remoteDataSource = FakeEventsRemoteDataSource();
    isOnline = true;
    repository = EventSyncRepositoryImpl(
      db: database,
      remoteDataSource: remoteDataSource,
      isOnlineChecker: () async => isOnline,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('EventSyncRepositoryImpl', () {
    test('records events to local SQLite database', () async {
      final event = ClientEvent(
        eventId: 'evt_1',
        eventType: 'TRACK_STARTED',
        occurredAt: DateTime.utc(2026, 10, 21, 10, 0, 0),
        sessionId: 'sess_123',
        trackId: 'track_1',
        properties: {
          'duration_ms': 180000,
        },
      );

      await repository.recordEvent(event);

      final count = await repository.getPendingEventCount();
      expect(count, equals(1));
    });

    test('syncPendingEvents uploads batch and deletes local rows on success', () async {
      for (int i = 0; i < 5; i++) {
        await repository.recordEvent(
          ClientEvent(
            eventId: 'evt_$i',
            eventType: 'TRACK_STARTED',
            occurredAt: DateTime.utc(2026, 10, 21, 10, 0, i),
            sessionId: 'sess_1',
            trackId: 'track_$i',
            properties: {'duration_ms': 180000},
          ),
        );
      }

      final countBefore = await repository.getPendingEventCount();
      expect(countBefore, equals(5));

      final result = await repository.syncPendingEvents(maxBatch: 100);

      expect(result, isA<ResultOk<int>>());
      expect((result as ResultOk<int>).value, equals(5));
      expect(remoteDataSource.sentBatches.length, equals(1));
      expect(remoteDataSource.sentBatches.first.length, equals(5));

      final countAfter = await repository.getPendingEventCount();
      expect(countAfter, equals(0));
    });

    test('syncPendingEvents respects maxBatch limit (up to 100)', () async {
      for (int i = 0; i < 15; i++) {
        await repository.recordEvent(
          ClientEvent(
            eventId: 'evt_$i',
            eventType: 'TRACK_PAUSED',
            occurredAt: DateTime.utc(2026, 10, 21, 10, 0, 0),
            sessionId: 'sess_1',
            trackId: 'track_$i',
            properties: {'position_ms': 1000},
          ),
        );
      }

      final result = await repository.syncPendingEvents(maxBatch: 10);

      expect(result, isA<ResultOk<int>>());
      expect((result as ResultOk<int>).value, equals(10));
      expect(remoteDataSource.sentBatches.first.length, equals(10));

      final countAfter = await repository.getPendingEventCount();
      expect(countAfter, equals(5));
    });

    test('syncPendingEvents does nothing when offline (skips network & keeps local events)', () async {
      isOnline = false;

      await repository.recordEvent(
        ClientEvent(
          eventId: 'evt_offline',
          eventType: 'TRACK_STARTED',
          occurredAt: DateTime.utc(2026, 10, 21, 10, 0, 0),
          sessionId: 'sess_1',
          trackId: 'track_1',
          properties: {'duration_ms': 180000},
        ),
      );

      final result = await repository.syncPendingEvents(maxBatch: 100);

      expect(result, isA<ResultOk<int>>());
      expect((result as ResultOk<int>).value, equals(0));
      expect(remoteDataSource.sentBatches, isEmpty);

      final countAfter = await repository.getPendingEventCount();
      expect(countAfter, equals(1));
    });

    test('syncPendingEvents keeps local events when remote API returns an error', () async {
      remoteDataSource.shouldFail = true;

      await repository.recordEvent(
        ClientEvent(
          eventId: 'evt_fail',
          eventType: 'TRACK_STARTED',
          occurredAt: DateTime.utc(2026, 10, 21, 10, 0, 0),
          sessionId: 'sess_1',
          trackId: 'track_1',
          properties: {'duration_ms': 180000},
        ),
      );

      final result = await repository.syncPendingEvents(maxBatch: 100);

      expect(result, isA<ResultError<int>>());
      final countAfter = await repository.getPendingEventCount();
      expect(countAfter, equals(1));
    });
  });
}

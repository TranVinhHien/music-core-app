import 'package:dio/dio.dart';
import 'package:flutter_clean_architecture_example/core/network/api_client.dart';
import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/events/data/datasources/events_remote_data_source.dart';
import 'package:flutter_clean_architecture_example/features/events/domain/entities/client_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventsRemoteDataSourceImpl', () {
    test('sends batch and logs cURL command', () async {
      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000',
        tokenGetter: () => 'mock_jwt_token',
      );

      // Add a mock response handler to the existing interceptor chain
      apiClient.rawDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'code': 200,
                  'message': 'success',
                  'data': {
                    'processed_event_ids': ['evt_1'],
                  },
                },
              ),
            );
          },
        ),
      );

      final dataSource = EventsRemoteDataSourceImpl(apiClient);

      final event = ClientEvent(
        eventId: 'evt_1',
        eventType: 'TRACK_STARTED',
        occurredAt: DateTime.utc(2026, 10, 22, 8, 0, 0),
        sessionId: 'sess_123',
        trackId: 'track_123',
        properties: {'duration_ms': 180000},
      );

      final result = await dataSource.sendEventBatch([event]);

      expect(result, isA<ResultOk<List<String>>>());
      expect((result as ResultOk<List<String>>).value, equals(['evt_1']));
    });
  });
}

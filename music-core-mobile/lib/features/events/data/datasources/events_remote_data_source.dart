import '../../../../core/network/api_client.dart';
import '../../../../core/result.dart';
import '../../domain/entities/client_event.dart';

abstract interface class EventsRemoteDataSource {
  Future<Result<List<String>>> sendEventBatch(List<ClientEvent> events);
}

class EventsRemoteDataSourceImpl implements EventsRemoteDataSource {
  const EventsRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Result<List<String>>> sendEventBatch(List<ClientEvent> events) async {
    if (events.isEmpty) {
      return const ResultOk(<String>[]);
    }

    final payload = {
      'events': events.map((ClientEvent e) => e.toJson()).toList(),
    };

    final result = await _apiClient.post(
      '/api/v1/listening-events/batch',
      data: payload,
    );

    return switch (result) {
      ResultOk(value: final data) => () {
          if (data is Map<String, dynamic>) {
            final rawList = data['processed_event_ids'];
            if (rawList is List) {
              final processedIds = rawList.map((e) => e.toString()).toList();
              return ResultOk(processedIds);
            }
          }
          return ResultOk(events.map((e) => e.eventId).toList());
        }(),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }
}

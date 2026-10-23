import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/result.dart';
import '../models/transition_plan_model.dart';

/// Data source interface for fetching harmonic transition plans from the backend.
abstract interface class TransitionRemoteDataSource {
  Future<Result<AutoDjTransitionResponse>> getNextTransition({
    required String currentTrackId,
    List<String>? excludeTrackIds,
    double temperature = 0.7,
  });
}

/// HTTP API client implementation that queries GET /api/v1/catalog/transitions/next using Dio/ApiClient.
class TransitionApiService implements TransitionRemoteDataSource {
  TransitionApiService({
    ApiClient? apiClient,
    Dio? dio,
  })  : _apiClient = apiClient,
        _dio = dio ?? apiClient?.rawDio;

  final ApiClient? _apiClient;
  final Dio? _dio;

  @override
  Future<Result<AutoDjTransitionResponse>> getNextTransition({
    required String currentTrackId,
    List<String>? excludeTrackIds,
    double temperature = 0.7,
  }) async {
    final queryParams = <String, dynamic>{
      'currentTrackId': currentTrackId,
      'temperature': temperature,
    };
    if (excludeTrackIds != null && excludeTrackIds.isNotEmpty) {
      queryParams['excludeTrackIds'] = excludeTrackIds.join(',');
    }

    if (_apiClient != null) {
      final res = await _apiClient.get(
        '/api/v1/catalog/transitions/next',
        queryParameters: queryParams,
      );
      return switch (res) {
        ResultOk(value: final rawData) => _parsePayload(rawData),
        ResultError(failure: final failure) => ResultError(failure),
      };
    } else if (_dio != null) {
      try {
        final res = await _dio.get<dynamic>(
          '/api/v1/catalog/transitions/next',
          queryParameters: queryParams,
        );
        return _parsePayload(res.data);
      } on DioException catch (e) {
        return ResultError(NetworkFailure(e.message ?? 'Dio request failed'));
      } catch (e) {
        return ResultError(NetworkFailure(e.toString()));
      }
    } else {
      return const ResultError(NetworkFailure('No HTTP client configured'));
    }
  }

  Result<AutoDjTransitionResponse> _parsePayload(dynamic rawData) {
    try {
      final data = (rawData is Map<String, dynamic> &&
              rawData['data'] is Map<String, dynamic>)
          ? rawData['data'] as Map<String, dynamic>
          : (rawData is Map<String, dynamic> ? rawData : null);

      if (data == null) {
        return const ResultError(
          ValidationFailure('Invalid or empty transition response body'),
        );
      }

      final parsed = AutoDjTransitionResponse.fromJson(data);
      return ResultOk(parsed);
    } catch (e) {
      return ResultError(
        ValidationFailure('Failed to deserialize transition plan: $e'),
      );
    }
  }
}

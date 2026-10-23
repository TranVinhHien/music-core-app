import 'package:dio/dio.dart';
import 'package:flutter_clean_architecture_example/core/network/api_client.dart';
import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/player/data/datasources/transition_api_service.dart';
import 'package:flutter_clean_architecture_example/features/player/data/models/transition_plan_model.dart';
import 'package:flutter_clean_architecture_example/features/player/data/repositories/transition_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransitionApiService & TransitionRepositoryImpl', () {
    test('fetches next transition plan successfully with correct query params', () async {
      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000',
        tokenGetter: () => 'mock_token',
      );

      RequestOptions? capturedOptions;

      apiClient.rawDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedOptions = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'code': '200',
                  'message': 'ok',
                  'data': {
                    'currentTrack': {
                      'id': 'curr-1',
                      'triggerTransitionAtMs': 300000,
                      'stopPlaybackAtMs': 310000,
                    },
                    'nextTrack': {
                      'id': 'next-2',
                      'title': 'Next Song',
                      'fileUrl': 'https://example.com/next.m4a',
                      'artists': ['Top Artist'],
                      'startPlaybackAtMs': 5000,
                    },
                    'transitionPlan': {
                      'transitionType': 'BEAT_CROSSFADE',
                      'crossfadeDurationMs': 10000,
                      'preBufferAtMs': 290000,
                      'volumeBalanceGainDb': -2.0,
                    },
                  },
                },
              ),
            );
          },
        ),
      );

      final apiService = TransitionApiService(apiClient: apiClient);
      final repository = TransitionRepositoryImpl(apiService);

      final result = await repository.getNextTransition(
        currentTrackId: 'curr-1',
        excludeTrackIds: ['ex-1', 'ex-2'],
        temperature: 0.8,
      );

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.path, '/api/v1/catalog/transitions/next');
      expect(capturedOptions!.queryParameters['currentTrackId'], 'curr-1');
      expect(capturedOptions!.queryParameters['excludeTrackIds'], 'ex-1,ex-2');
      expect(capturedOptions!.queryParameters['temperature'], 0.8);

      expect(result, isA<ResultOk<AutoDjTransitionResponse>>());
      final plan = (result as ResultOk<AutoDjTransitionResponse>).value;
      expect(plan.currentTrack.id, 'curr-1');
      expect(plan.currentTrack.triggerTransitionAtMs, 300000);
      expect(plan.nextTrack.id, 'next-2');
      expect(plan.nextTrack.title, 'Next Song');
      expect(plan.transitionPlan.crossfadeDurationMs, 10000);
      expect(plan.transitionPlan.volumeBalanceGainDb, -2.0);
    });

    test('handles 404 or missing candidate track error cleanly', () async {
      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000',
      );

      apiClient.rawDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 404,
                  data: {'message': 'No eligible candidate track found'},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

      final apiService = TransitionApiService(apiClient: apiClient);
      final result = await apiService.getNextTransition(currentTrackId: 'curr-99');

      expect(result, isA<ResultError<AutoDjTransitionResponse>>());
    });

    test('handles direct payload without outer data wrapper', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'currentTrack': {
                    'id': 'curr-direct',
                    'triggerTransitionAtMs': 1000,
                    'stopPlaybackAtMs': 2000,
                  },
                  'nextTrack': {
                    'id': 'next-direct',
                    'title': 'Direct Song',
                    'startPlaybackAtMs': 0,
                  },
                  'transitionPlan': {
                    'transitionType': 'SMOOTH_FADE',
                    'crossfadeDurationMs': 1000,
                    'preBufferAtMs': 500,
                    'volumeBalanceGainDb': 0.0,
                  },
                },
              ),
            );
          },
        ),
      );

      final apiService = TransitionApiService(dio: dio);
      final result = await apiService.getNextTransition(currentTrackId: 'curr-direct');

      expect(result, isA<ResultOk<AutoDjTransitionResponse>>());
      final plan = (result as ResultOk<AutoDjTransitionResponse>).value;
      expect(plan.currentTrack.id, 'curr-direct');
      expect(plan.nextTrack.id, 'next-direct');
    });
  });
}

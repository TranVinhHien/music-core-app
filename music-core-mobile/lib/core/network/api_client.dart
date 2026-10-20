import 'dart:io';
import 'package:dio/dio.dart';
import '../result.dart';

/// Central HTTP Client wrapping Dio with unified interceptors and error mappings.
class ApiClient {
  ApiClient({
    required String baseUrl,
    String? Function()? tokenGetter,
    Future<String?> Function()? onRefreshToken,
    Future<void> Function()? onAuthenticationFailed,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (tokenGetter != null) {
            final token = tokenGetter();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (err, handler) async {
          final statusCode = err.response?.statusCode;
          final path = err.requestOptions.path;

          final isAuthEndpoint = path.contains('/auth/login') ||
              path.contains('/auth/refresh') ||
              path.contains('/auth/register');

          if (statusCode == HttpStatus.unauthorized &&
              !isAuthEndpoint &&
              onRefreshToken != null) {
            final newToken = await _getRefreshedToken(onRefreshToken);
            if (newToken != null && newToken.isNotEmpty) {
              try {
                final options = err.requestOptions;
                options.headers['Authorization'] = 'Bearer $newToken';
                final response = await _dio.fetch<dynamic>(options);
                return handler.resolve(response);
              } on DioException catch (retryErr) {
                return handler.next(retryErr);
              } catch (_) {
                return handler.next(err);
              }
            } else {
              if (onAuthenticationFailed != null) {
                await onAuthenticationFailed();
              }
            }
          }

          return handler.next(err);
        },
      ),
    );
  }

  Future<String?>? _ongoingRefresh;

  Future<String?> _getRefreshedToken(Future<String?> Function() refreshHandler) {
    if (_ongoingRefresh != null) {
      return _ongoingRefresh!;
    }
    _ongoingRefresh = refreshHandler().whenComplete(() {
      _ongoingRefresh = null;
    });
    return _ongoingRefresh!;
  }

  final Dio _dio;

  Dio get rawDio => _dio;

  /// Perform a GET request
  Future<Result<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      return ResultError(_mapDioError(e));
    } catch (e) {
      return ResultError(NetworkFailure(e.toString()));
    }
  }

  /// Perform a POST request
  Future<Result<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      return ResultError(_mapDioError(e));
    } catch (e) {
      return ResultError(NetworkFailure(e.toString()));
    }
  }

  /// Perform a PUT request
  Future<Result<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      return ResultError(_mapDioError(e));
    } catch (e) {
      return ResultError(NetworkFailure(e.toString()));
    }
  }

  /// Perform a DELETE request
  Future<Result<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      return ResultError(_mapDioError(e));
    } catch (e) {
      return ResultError(NetworkFailure(e.toString()));
    }
  }

  Result<dynamic> _handleResponse(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      // Backend returns {"code": 200/201, "message": "...", "data": ...}
      final data = body['data'];
      return ResultOk(data);
    }
    return ResultOk(body);
  }

  AppFailure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkFailure('Unable to connect to server. Please check your network.');
    }

    final response = e.response;
    if (response != null) {
      String errorMessage = 'Request failed';
      if (response.data is Map<String, dynamic>) {
        final message = response.data['message'] ?? response.data['error'];
        if (message != null) {
          errorMessage = message.toString();
        }
      }

      final statusCode = response.statusCode;
      if (statusCode == HttpStatus.unauthorized) {
        return UnauthorizedFailure(errorMessage);
      }
      if (statusCode == HttpStatus.conflict) {
        return ConflictFailure(errorMessage);
      }
      if (statusCode == HttpStatus.badRequest) {
        return ValidationFailure(errorMessage);
      }
      if (statusCode != null && statusCode >= 500) {
        return ServerFailure(errorMessage);
      }

      return ValidationFailure(errorMessage);
    }

    return NetworkFailure(e.message ?? 'Unknown network failure');
  }
}

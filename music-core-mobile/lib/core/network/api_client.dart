import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../result.dart';

/// Central HTTP Client wrapping Dio with unified interceptors, global cURL logging, and error mappings.
class ApiClient {
  ApiClient({
    required String baseUrl,
    this.tokenGetter,
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
          final token = tokenGetter?.call();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          _logRequest(options);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          String formattedBody;
          try {
            if (response.data is Map || response.data is List) {
              formattedBody =
                  const JsonEncoder.withIndent('  ').convert(response.data);
            } else {
              formattedBody = response.data?.toString() ?? '';
            }
          } catch (_) {
            formattedBody = response.data?.toString() ?? '';
          }

          _logResponse(response, formattedBody);
          return handler.next(response);
        },
        onError: (err, handler) async {
          String formattedBody = '';
          if (err.response?.data != null) {
            try {
              if (err.response!.data is Map || err.response!.data is List) {
                formattedBody = const JsonEncoder.withIndent('  ')
                    .convert(err.response!.data);
              } else {
                formattedBody = err.response!.data.toString();
              }
            } catch (_) {
              formattedBody = err.response!.data.toString();
            }
          }

          _logError(err, formattedBody);

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

  static String _generateCurl(RequestOptions options) {
    final buffer = StringBuffer('curl -i -X ${options.method} "${options.uri}"');

    options.headers.forEach((key, value) {
      if (value != null) {
        buffer.write(' \\\n  -H "$key: $value"');
      }
    });

    if (options.data != null) {
      String dataString;
      if (options.data is Map || options.data is List) {
        try {
          dataString = const JsonEncoder.withIndent('  ').convert(options.data);
        } catch (_) {
          dataString = options.data.toString();
        }
      } else if (options.data is FormData) {
        final formData = options.data as FormData;
        dataString = formData.fields.map((e) => '${e.key}=${e.value}').join('&');
      } else {
        dataString = options.data.toString();
      }
      buffer.write(" \\\n  -d '$dataString'");
    }

    return buffer.toString();
  }

  static String _generateSingleLineCurl(RequestOptions options) {
    final buffer = StringBuffer('curl -i -X ${options.method} "${options.uri}"');

    options.headers.forEach((key, value) {
      if (value != null) {
        buffer.write(' -H "$key: $value"');
      }
    });

    if (options.data != null) {
      String dataString;
      if (options.data is Map || options.data is List) {
        try {
          dataString = jsonEncode(options.data);
        } catch (_) {
          dataString = options.data.toString();
        }
      } else if (options.data is FormData) {
        final formData = options.data as FormData;
        dataString = formData.fields.map((e) => '${e.key}=${e.value}').join('&');
      } else {
        dataString = options.data.toString();
      }
      buffer.write(" -d '$dataString'");
    }

    return buffer.toString();
  }

  static void _logRaw(String text) {
    // In Flutter, print() is intercepted by UIDartState::Log and guaranteed to stream to `flutter run` console.
    print(text);
  }

  static void _logRequest(RequestOptions options) {
    final singleLineCurl = _generateSingleLineCurl(options);
    final multiLineCurl = _generateCurl(options);
    _logRaw(
      '\n>>> [HTTP REQUEST cURL]\n'
      '# One-line (copy-paste directly without line wrapping):\n'
      '$singleLineCurl\n\n'
      '# Formatted:\n'
      '$multiLineCurl\n'
      '<<< [END cURL]\n',
    );
  }

  static void _logResponse(Response<dynamic> response, String formattedBody) {
    _logRaw(
      '\n>>> [HTTP RESPONSE: ${response.statusCode} ${response.statusMessage ?? 'OK'}] ${response.requestOptions.method} ${response.requestOptions.uri}\n'
      '${formattedBody.isNotEmpty ? '$formattedBody\n' : ''}'
      '<<< [END RESPONSE]\n',
    );
  }

  static void _logError(DioException err, String formattedBody) {
    _logRaw(
      '\n>>> [HTTP ERROR: ${err.response?.statusCode ?? 'NO_STATUS'}] ${err.requestOptions.method} ${err.requestOptions.uri}\n'
      'Message: ${err.message}\n'
      '${formattedBody.isNotEmpty ? '$formattedBody\n' : ''}'
      '<<< [END ERROR]\n',
    );
  }

  /// Create a standalone logging interceptor that can be attached to any Dio instance.
  static Interceptor createLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        _logRequest(options);
        return handler.next(options);
      },
      onResponse: (response, handler) {
        String formattedBody;
        try {
          if (response.data is Map || response.data is List) {
            formattedBody =
                const JsonEncoder.withIndent('  ').convert(response.data);
          } else {
            formattedBody = response.data?.toString() ?? '';
          }
        } catch (_) {
          formattedBody = response.data?.toString() ?? '';
        }

        _logResponse(response, formattedBody);
        return handler.next(response);
      },
      onError: (err, handler) {
        String formattedBody = '';
        if (err.response?.data != null) {
          try {
            if (err.response!.data is Map || err.response!.data is List) {
              formattedBody = const JsonEncoder.withIndent('  ')
                  .convert(err.response!.data);
            } else {
              formattedBody = err.response!.data.toString();
            }
          } catch (_) {
            formattedBody = err.response!.data.toString();
          }
        }

        _logError(err, formattedBody);
        return handler.next(err);
      },
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
  final String? Function()? tokenGetter;

  Dio get rawDio => _dio;
  String get baseUrl => _dio.options.baseUrl;

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
        final message = response.data['message'] ?? response.data['error'] ?? response.data['data'];
        if (message != null) {
          errorMessage = message.toString();
        }
      } else if (response.data is String) {
        errorMessage = response.data as String;
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

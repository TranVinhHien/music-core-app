import '../../../../core/network/api_client.dart';
import '../../../../core/result.dart';
import '../../domain/entities/auth_session.dart';

abstract interface class AuthRemoteDataSource {
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  });

  Future<Result<void>> register({
    required String email,
    required String password,
    required String fullName,
    String? avatarUrl,
    String? phoneNumber,
    String? homeAddress,
  });

  Future<Result<void>> logout(String refreshToken);

  Future<Result<AuthSession>> refreshToken(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.post(
      '/api/v1/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    return switch (result) {
      ResultOk(value: final data) => () {
          if (data is Map<String, dynamic>) {
            return ResultOk(AuthSession.fromJson(data));
          }
          return const ResultError<AuthSession>(
            ValidationFailure('Invalid login response format from server'),
          );
        }(),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }

  @override
  Future<Result<void>> register({
    required String email,
    required String password,
    required String fullName,
    String? avatarUrl,
    String? phoneNumber,
    String? homeAddress,
  }) async {
    final payload = <String, dynamic>{
      'email': email,
      'password': password,
      'full_name': fullName,
    };
    if (avatarUrl != null) {
      payload['avatar_url'] = avatarUrl;
    }
    if (phoneNumber != null) {
      payload['phone_number'] = phoneNumber;
    }
    if (homeAddress != null) {
      payload['home_address'] = homeAddress;
    }

    final result = await _apiClient.post(
      '/api/v1/auth/register',
      data: payload,
    );

    return switch (result) {
      ResultOk() => const ResultOk(null),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }

  @override
  Future<Result<void>> logout(String refreshToken) async {
    final result = await _apiClient.post(
      '/api/v1/auth/logout',
      data: {
        'refresh_token': refreshToken,
      },
    );

    return switch (result) {
      ResultOk() => const ResultOk(null),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }

  @override
  Future<Result<AuthSession>> refreshToken(String refreshToken) async {
    final result = await _apiClient.post(
      '/api/v1/auth/refresh',
      data: {
        'refresh_token': refreshToken,
      },
    );

    return switch (result) {
      ResultOk(value: final data) => () {
          if (data is Map<String, dynamic>) {
            return ResultOk(AuthSession.fromJson(data));
          }
          return const ResultError<AuthSession>(
            ValidationFailure('Invalid refresh token response format from server'),
          );
        }(),
      ResultError(failure: final failure) => ResultError(failure),
    };
  }
}

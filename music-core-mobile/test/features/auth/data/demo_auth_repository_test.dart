import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/auth/data/auth_repository_impl.dart';
import 'package:flutter_clean_architecture_example/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_clean_architecture_example/features/auth/data/session_storage.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRepositoryImpl', () {
    const testSession = AuthSession(
      user: UserEntity(
        id: 'user-1',
        email: 'test@example.com',
        fullName: 'Test User',
      ),
      accessToken: 'test-token',
      refreshToken: 'test-refresh-token',
      sessionId: 'test-session-id',
    );

    test('signs in successfully and saves session to local storage', () async {
      final remote = _FakeAuthRemoteDataSource(loginResult: const ResultOk(testSession));
      final storage = _FakeSessionStorage();
      final repository = AuthRepositoryImpl(remote, storage);

      final result = await repository.signIn('test@example.com', 'password123');

      expect(result, isA<ResultOk<AuthSession>>());
      expect((result as ResultOk).value, testSession);
      expect(storage.session, testSession);
    });

    test('returns failure and does not save session when login fails', () async {
      final remote = _FakeAuthRemoteDataSource(
        loginResult: const ResultError(UnauthorizedFailure('Invalid password')),
      );
      final storage = _FakeSessionStorage();
      final repository = AuthRepositoryImpl(remote, storage);

      final result = await repository.signIn('test@example.com', 'wrong');

      expect(result, isA<ResultError<AuthSession>>());
      expect((result as ResultError).failure, isA<UnauthorizedFailure>());
      expect(storage.session, isNull);
    });

    test('restores session from local storage', () async {
      final remote = _FakeAuthRemoteDataSource();
      final storage = _FakeSessionStorage()..session = testSession;
      final repository = AuthRepositoryImpl(remote, storage);

      final result = await repository.restoreSession();

      expect(result, isA<ResultOk<AuthSession?>>());
      expect((result as ResultOk).value, testSession);
    });

    test('registers user via remote data source', () async {
      final remote = _FakeAuthRemoteDataSource(registerResult: const ResultOk(null));
      final storage = _FakeSessionStorage();
      final repository = AuthRepositoryImpl(remote, storage);

      final result = await repository.register(
        email: 'new@example.com',
        password: 'password123',
        fullName: 'New User',
      );

      expect(result, isA<ResultOk<void>>());
      expect(remote.registeredEmail, 'new@example.com');
    });

    test('signs out by clearing local session and calling remote logout', () async {
      final remote = _FakeAuthRemoteDataSource();
      final storage = _FakeSessionStorage()..session = testSession;
      final repository = AuthRepositoryImpl(remote, storage);

      final result = await repository.signOut();

      expect(result, isA<ResultOk<void>>());
      expect(storage.session, isNull);
      expect(remote.loggedOutRefreshToken, 'test-refresh-token');
    });

    test('refreshes token successfully and updates session in storage', () async {
      const refreshedSession = AuthSession(
        user: UserEntity(
          id: 'user-1',
          email: 'test@example.com',
          fullName: 'Test User',
        ),
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
        sessionId: 'refreshed-session-id',
      );
      final remote = _FakeAuthRemoteDataSource(
        refreshTokenResult: const ResultOk(refreshedSession),
      );
      final storage = _FakeSessionStorage()..session = testSession;
      final repository = AuthRepositoryImpl(remote, storage);

      final result = await repository.refreshToken();

      expect(result, isA<ResultOk<AuthSession>>());
      expect((result as ResultOk).value.accessToken, 'new-access-token');
      expect(storage.session?.accessToken, 'new-access-token');
      expect(storage.session?.sessionId, 'refreshed-session-id');
    });

    test('clears session when refresh token is rejected', () async {
      final remote = _FakeAuthRemoteDataSource(
        refreshTokenResult: const ResultError(UnauthorizedFailure('Token expired')),
      );
      final storage = _FakeSessionStorage()..session = testSession;
      final repository = AuthRepositoryImpl(remote, storage);

      final result = await repository.refreshToken();

      expect(result, isA<ResultError<AuthSession>>());
      expect(storage.session, isNull);
    });
  });
}

final class _FakeSessionStorage implements SessionStorage {
  AuthSession? session;

  @override
  String? get cachedAccessToken => session?.accessToken;

  @override
  String? get cachedSessionId => session?.sessionId;

  @override
  Future<void> clearSession() async {
    session = null;
  }

  @override
  Future<AuthSession?> readSession() async => session;

  @override
  Future<void> writeSession(AuthSession session) async {
    this.session = session;
  }
}

final class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  _FakeAuthRemoteDataSource({
    this.loginResult = const ResultError(UnauthorizedFailure('')),
    this.registerResult = const ResultOk(null),
    this.refreshTokenResult = const ResultError(UnauthorizedFailure('')),
  });

  final Result<AuthSession> loginResult;
  final Result<void> registerResult;
  final Result<AuthSession> refreshTokenResult;
  String? registeredEmail;
  String? loggedOutRefreshToken;

  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async =>
      loginResult;

  @override
  Future<Result<void>> register({
    required String email,
    required String password,
    required String fullName,
    String? avatarUrl,
    String? phoneNumber,
    String? homeAddress,
  }) async {
    registeredEmail = email;
    return registerResult;
  }

  @override
  Future<Result<void>> logout(String refreshToken) async {
    loggedOutRefreshToken = refreshToken;
    return const ResultOk(null);
  }

  @override
  Future<Result<AuthSession>> refreshToken(String refreshToken) async =>
      refreshTokenResult;
}

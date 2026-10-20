import '../../../../core/result.dart';
import '../domain/entities/auth_session.dart';
import '../domain/repositories/auth_repository.dart';
import 'datasources/auth_remote_data_source.dart';
import 'session_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource, this._sessionStorage);

  final AuthRemoteDataSource _remoteDataSource;
  final SessionStorage _sessionStorage;

  @override
  Future<Result<AuthSession?>> restoreSession() async {
    try {
      final session = await _sessionStorage.readSession();
      return ResultOk(session);
    } catch (e) {
      return ResultError(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<AuthSession>> signIn(String email, String password) async {
    final result = await _remoteDataSource.login(
      email: email,
      password: password,
    );

    switch (result) {
      case ResultOk(value: final session):
        try {
          await _sessionStorage.writeSession(session);
          return ResultOk(session);
        } catch (e) {
          return ResultError(StorageFailure('Failed to save session locally: $e'));
        }
      case ResultError(failure: final failure):
        return ResultError(failure);
    }
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
    return _remoteDataSource.register(
      email: email,
      password: password,
      fullName: fullName,
      avatarUrl: avatarUrl,
      phoneNumber: phoneNumber,
      homeAddress: homeAddress,
    );
  }

  @override
  Future<Result<void>> signOut() async {
    final session = await _sessionStorage.readSession();
    if (session?.refreshToken != null && session!.refreshToken!.isNotEmpty) {
      // Fire-and-forget or best-effort remote logout
      await _remoteDataSource.logout(session.refreshToken!);
    }
    await _sessionStorage.clearSession();
    return const ResultOk(null);
  }

  @override
  Future<Result<AuthSession>> refreshToken() async {
    final session = await _sessionStorage.readSession();
    final refreshToken = session?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return const ResultError(UnauthorizedFailure('No refresh token available'));
    }

    final result = await _remoteDataSource.refreshToken(refreshToken);
    switch (result) {
      case ResultOk(value: final newSession):
        try {
          final updatedSession = AuthSession(
            user: newSession.user.id.isNotEmpty ? newSession.user : session!.user,
            accessToken: newSession.accessToken,
            refreshToken: (newSession.refreshToken != null && newSession.refreshToken!.isNotEmpty)
                ? newSession.refreshToken
                : refreshToken,
          );
          await _sessionStorage.writeSession(updatedSession);
          return ResultOk(updatedSession);
        } catch (e) {
          return ResultError(StorageFailure('Failed to update session locally: $e'));
        }
      case ResultError(failure: final failure):
        if (failure is UnauthorizedFailure) {
          await _sessionStorage.clearSession();
        }
        return ResultError(failure);
    }
  }
}

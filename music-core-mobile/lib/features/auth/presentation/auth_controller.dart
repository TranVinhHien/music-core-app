import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/dependencies.dart';
import '../../../core/result.dart';
import '../domain/entities/auth_session.dart';

part 'auth_controller.g.dart';

/// Owns the app-wide authenticated user session and authentication actions.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  Future<AuthSession?> build() async {
    final result = await ref.read(authRepositoryProvider).restoreSession();
    return switch (result) {
      ResultOk(value: final session) => session,
      ResultError(failure: final failure) => throw failure,
    };
  }

  Future<AppFailure?> signIn(String email, String password) async {
    final previousSession = state.value;
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).signIn(
          email.trim(),
          password,
        );
    switch (result) {
      case ResultOk(value: final session):
        state = AsyncData(session);
        return null;
      case ResultError(failure: final failure):
        state = AsyncData(previousSession);
        return failure;
    }
  }

  Future<AppFailure?> register({
    required String email,
    required String password,
    required String fullName,
    String? avatarUrl,
    String? phoneNumber,
    String? homeAddress,
  }) async {
    final previousSession = state.value;
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).register(
          email: email.trim(),
          password: password,
          fullName: fullName.trim(),
          avatarUrl: avatarUrl,
          phoneNumber: phoneNumber,
          homeAddress: homeAddress,
        );
    switch (result) {
      case ResultOk():
        // Auto sign in after successful registration
        return signIn(email, password);
      case ResultError(failure: final failure):
        state = AsyncData(previousSession);
        return failure;
    }
  }

  Future<AppFailure?> signOut() async {
    final previousSession = state.value;
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).signOut();
    switch (result) {
      case ResultOk():
        state = const AsyncData(null);
        return null;
      case ResultError(failure: final failure):
        state = AsyncData(previousSession);
        return failure;
    }
  }

  Future<void> retry() async {
    ref.invalidateSelf();
    await future;
  }

  void clearSession() {
    state = const AsyncData(null);
  }

  Future<bool> refreshSession() async {
    final result = await ref.read(authRepositoryProvider).refreshToken();
    switch (result) {
      case ResultOk(value: final session):
        state = AsyncData(session);
        return true;
      case ResultError():
        state = const AsyncData(null);
        return false;
    }
  }
}

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/result.dart';
import '../domain/entities/demo_account.dart';
import '../../../app/dependencies.dart';

part 'auth_controller.g.dart';

/// Owns the app-wide active Demo account and its session commands.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  Future<DemoAccount?> build() async {
    final result = await ref.read(authRepositoryProvider).restoreSession();
    return switch (result) {
      ResultOk(value: final account) => account,
      ResultError(failure: final failure) => throw failure,
    };
  }

  Future<AppFailure?> signIn(String email, String password) async {
    final previousAccount = state.value;
    state = const AsyncLoading();
    final result = await ref
        .read(authRepositoryProvider)
        .signIn(email, password);
    switch (result) {
      case ResultOk(value: final account):
        state = AsyncData(account);
        return null;
      case ResultError(failure: final failure):
        state = AsyncData(previousAccount);
        return failure;
    }
  }

  Future<AppFailure?> signOut() async {
    final previousAccount = state.value;
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).signOut();
    switch (result) {
      case ResultOk():
        state = const AsyncData(null);
        return null;
      case ResultError(failure: final failure):
        state = AsyncData(previousAccount);
        return failure;
    }
  }

  Future<void> retry() async {
    ref.invalidateSelf();
    await future;
  }
}

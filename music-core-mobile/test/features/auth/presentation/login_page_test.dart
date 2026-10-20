import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_example/app/dependencies.dart';
import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_clean_architecture_example/features/auth/presentation/login_page.dart';
import 'package:flutter_clean_architecture_example/features/auth/presentation/auth_widget_keys.dart';
import 'package:flutter_clean_architecture_example/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows validation messages for empty credentials', (
    tester,
  ) async {
    await _pumpLogin(tester, _FakeAuthRepository());

    await tester.tap(find.byKey(AuthWidgetKeys.loginButton));
    await tester.pump();

    expect(find.text('Enter an email address.'), findsOneWidget);
    expect(find.text('Enter a password.'), findsOneWidget);
  });

  testWidgets('shows a typed authentication error without leaving the page', (
    tester,
  ) async {
    await _pumpLogin(tester, _FakeAuthRepository(rejectSignIn: true));

    await _enterCredentials(tester, password: 'wrong-password');
    await tester.tap(find.byKey(AuthWidgetKeys.loginButton));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('The email or password is incorrect.'), findsOneWidget);
  });

  testWidgets('disables only the submit control while signing in', (
    tester,
  ) async {
    final pendingSignIn = Completer<Result<AuthSession>>();
    await _pumpLogin(tester, _FakeAuthRepository(pendingSignIn: pendingSignIn));

    await _enterCredentials(tester);
    await tester.tap(find.byKey(AuthWidgetKeys.loginButton));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.byKey(AuthWidgetKeys.loginButton),
    );
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pendingSignIn.complete(const ResultError(UnauthorizedFailure('')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ElevatedButton>(find.byKey(AuthWidgetKeys.loginButton))
          .onPressed,
      isNotNull,
    );
  });
}

Future<void> _enterCredentials(
  WidgetTester tester, {
  String email = 'user@example.com',
  String password = 'password123',
}) async {
  await tester.enterText(find.byKey(AuthWidgetKeys.loginEmail), email);
  await tester.enterText(find.byKey(AuthWidgetKeys.loginPassword), password);
}

Future<void> _pumpLogin(
  WidgetTester tester,
  _FakeAuthRepository repository, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LoginPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.rejectSignIn = false, this.pendingSignIn});

  final bool rejectSignIn;
  final Completer<Result<AuthSession>>? pendingSignIn;

  @override
  Future<Result<AuthSession?>> restoreSession() async => const ResultOk(null);

  @override
  Future<Result<AuthSession>> signIn(String email, String password) async {
    final pending = pendingSignIn;
    if (pending != null) return pending.future;
    if (rejectSignIn) return const ResultError(UnauthorizedFailure(''));
    return const ResultOk(
      AuthSession(
        user: UserEntity(
          id: '1',
          email: 'user@example.com',
          fullName: 'Test User',
        ),
        accessToken: 'mock_token',
      ),
    );
  }

  @override
  Future<Result<void>> register({
    required String email,
    required String password,
    required String fullName,
    String? avatarUrl,
    String? phoneNumber,
    String? homeAddress,
  }) async =>
      const ResultOk(null);

  @override
  Future<Result<void>> signOut() async => const ResultOk(null);

  @override
  Future<Result<AuthSession>> refreshToken() async =>
      const ResultError(UnauthorizedFailure('Not implemented'));
}

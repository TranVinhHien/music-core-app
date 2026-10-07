import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_example/app/dependencies.dart';
import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/entities/demo_account.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/entities/demo_accounts.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/failures/auth_failure.dart';
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
    final pendingSignIn = Completer<Result<DemoAccount>>();
    await _pumpLogin(tester, _FakeAuthRepository(pendingSignIn: pendingSignIn));

    await _enterCredentials(tester);
    await tester.tap(find.byKey(AuthWidgetKeys.loginButton));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(AuthWidgetKeys.loginButton),
    );
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(DemoAccounts.alice.email), findsWidgets);

    pendingSignIn.complete(const ResultError(InvalidCredentialsFailure()));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(find.byKey(AuthWidgetKeys.loginButton))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('uses natural Chinese login text', (tester) async {
    await _pumpLogin(tester, _FakeAuthRepository(), locale: const Locale('zh'));

    expect(find.text('使用以下任一演示账号登录，即可体验应用。'), findsOneWidget);
    expect(find.text('演示账号'), findsOneWidget);
    expect(find.text('邮箱地址'), findsOneWidget);
  });
}

Future<void> _enterCredentials(
  WidgetTester tester, {
  String password = DemoAccounts.password,
}) async {
  await tester.enterText(
    find.byKey(AuthWidgetKeys.loginEmail),
    DemoAccounts.alice.email,
  );
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
  final Completer<Result<DemoAccount>>? pendingSignIn;

  @override
  Future<Result<DemoAccount?>> restoreSession() async => const ResultOk(null);

  @override
  Future<Result<DemoAccount>> signIn(String email, String password) async {
    final pending = pendingSignIn;
    if (pending != null) return pending.future;
    if (rejectSignIn) return const ResultError(InvalidCredentialsFailure());
    return const ResultOk(DemoAccounts.alice);
  }

  @override
  Future<Result<void>> signOut() async => const ResultOk(null);
}

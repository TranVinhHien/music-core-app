import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture_example/app/dependencies.dart';
import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_clean_architecture_example/features/auth/presentation/register_page.dart';
import 'package:flutter_clean_architecture_example/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows validation errors when fields are empty', (tester) async {
    await _pumpRegister(tester, _FakeRegisterAuthRepository());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng ký'));
    await tester.pump();

    expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
    expect(find.text('Enter an email address.'), findsOneWidget);
    expect(find.text('Enter a password.'), findsOneWidget);
  });

  testWidgets('registers and auto signs in successfully', (tester) async {
    final fakeRepo = _FakeRegisterAuthRepository();
    await _pumpRegister(tester, fakeRepo);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nhập họ và tên của bạn'),
      'Nguyen Van A',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'name@example.com'),
      'nguyenvana@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'password123',
    );
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'password123',
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng ký'));
    await tester.pumpAndSettle();

    expect(fakeRepo.registeredEmail, 'nguyenvana@example.com');
    expect(fakeRepo.registeredFullName, 'Nguyen Van A');
  });
}

Future<void> _pumpRegister(
  WidgetTester tester,
  _FakeRegisterAuthRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RegisterPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _FakeRegisterAuthRepository implements AuthRepository {
  String? registeredEmail;
  String? registeredFullName;

  @override
  Future<Result<AuthSession?>> restoreSession() async => const ResultOk(null);

  @override
  Future<Result<AuthSession>> signIn(String email, String password) async =>
      const ResultOk(
        AuthSession(
          user: UserEntity(id: '1', email: 'test@example.com', fullName: 'Test'),
          accessToken: 'token',
        ),
      );

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
    registeredFullName = fullName;
    return const ResultOk(null);
  }

  @override
  Future<Result<void>> signOut() async => const ResultOk(null);

  @override
  Future<Result<AuthSession>> refreshToken() async =>
      const ResultError(UnauthorizedFailure('Not implemented'));
}

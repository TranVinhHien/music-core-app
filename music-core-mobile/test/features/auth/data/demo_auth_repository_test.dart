import 'package:flutter_clean_architecture_example/core/result.dart';
import 'package:flutter_clean_architecture_example/features/auth/data/demo_auth_repository.dart';
import 'package:flutter_clean_architecture_example/features/auth/data/session_storage.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/entities/demo_account.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/entities/demo_accounts.dart';
import 'package:flutter_clean_architecture_example/features/auth/domain/failures/auth_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DemoAuthRepository', () {
    test('signs in a known account and persists only its ID', () async {
      final storage = _FakeSessionStorage();
      final repository = DemoAuthRepository(storage);

      final result = await repository.signIn(
        ' ALICE@example.com ',
        DemoAccounts.password,
      );

      expect(result, isA<ResultOk<DemoAccount>>());
      expect((result as ResultOk).value, DemoAccounts.alice);
      expect(storage.accountId, DemoAccounts.alice.id);
    });

    test('rejects unknown credentials without writing a session', () async {
      final storage = _FakeSessionStorage();
      final repository = DemoAuthRepository(storage);

      final result = await repository.signIn(
        'unknown@example.com',
        DemoAccounts.password,
      );

      expect(result, isA<ResultError<DemoAccount>>());
      expect((result as ResultError).failure, isA<InvalidCredentialsFailure>());
      expect(storage.accountId, isNull);
    });

    test('restores a known session and clears an unknown one', () async {
      final storage = _FakeSessionStorage()..accountId = DemoAccounts.bob.id;
      final repository = DemoAuthRepository(storage);

      final restored = await repository.restoreSession();
      expect((restored as ResultOk).value, DemoAccounts.bob);

      storage.accountId = 'removed-account';
      final missing = await repository.restoreSession();
      expect((missing as ResultOk).value, isNull);
      expect(storage.accountId, isNull);
    });

    test('signs out by clearing the active account ID', () async {
      final storage = _FakeSessionStorage()..accountId = DemoAccounts.alice.id;
      final repository = DemoAuthRepository(storage);

      final result = await repository.signOut();

      expect(result, isA<ResultOk<void>>());
      expect(storage.accountId, isNull);
    });

    test('maps session storage failures to a storage failure', () async {
      final repository = DemoAuthRepository(
        _FakeSessionStorage(throwOnRead: true),
      );

      final result = await repository.restoreSession();

      expect(result, isA<ResultError<DemoAccount?>>());
      expect((result as ResultError).failure, isA<StorageFailure>());
    });

    test(
      'does not report sign-in success when session persistence fails',
      () async {
        final repository = DemoAuthRepository(
          _FakeSessionStorage(throwOnWrite: true),
        );

        final result = await repository.signIn(
          DemoAccounts.alice.email,
          DemoAccounts.password,
        );

        expect(result, isA<ResultError<DemoAccount>>());
        expect((result as ResultError).failure, isA<StorageFailure>());
      },
    );

    test(
      'maps sign-out storage failures without changing the contract',
      () async {
        final repository = DemoAuthRepository(
          _FakeSessionStorage(throwOnClear: true),
        );

        final result = await repository.signOut();

        expect(result, isA<ResultError<void>>());
        expect((result as ResultError).failure, isA<StorageFailure>());
      },
    );

    test('does not hide programming errors as storage failures', () async {
      final repository = DemoAuthRepository(
        _FakeSessionStorage(throwProgrammingErrorOnRead: true),
      );

      await expectLater(
        repository.restoreSession(),
        throwsA(isA<StateError>()),
      );
    });
  });
}

final class _FakeSessionStorage implements SessionStorage {
  _FakeSessionStorage({
    this.throwOnRead = false,
    this.throwOnWrite = false,
    this.throwOnClear = false,
    this.throwProgrammingErrorOnRead = false,
  });

  String? accountId;
  final bool throwOnRead;
  final bool throwOnWrite;
  final bool throwOnClear;
  final bool throwProgrammingErrorOnRead;

  @override
  Future<void> clearAccountId() async {
    if (throwOnClear) throw Exception('clear failed');
    accountId = null;
  }

  @override
  Future<String?> readAccountId() async {
    if (throwProgrammingErrorOnRead) throw StateError('read failed');
    if (throwOnRead) throw Exception('read failed');
    return accountId;
  }

  @override
  Future<void> writeAccountId(String accountId) async {
    if (throwOnWrite) throw Exception('write failed');
    this.accountId = accountId;
  }
}

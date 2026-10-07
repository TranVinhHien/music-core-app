import '../../../../core/result.dart';
import '../domain/entities/demo_account.dart';
import '../domain/entities/demo_accounts.dart';
import '../domain/failures/auth_failure.dart';
import '../domain/repositories/auth_repository.dart';
import 'session_storage.dart';

/// Deterministic local adapter used by both flavors.
///
/// This is deliberately a Demo session, not an OAuth or production
/// authentication implementation. No password or token is persisted.
final class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository(this._sessionStorage);

  final SessionStorage _sessionStorage;

  @override
  Future<Result<DemoAccount?>> restoreSession() async {
    try {
      final accountId = await _sessionStorage.readAccountId();
      if (accountId == null) return const ResultOk(null);

      final account = DemoAccounts.byId(accountId);
      if (account == null) {
        await _sessionStorage.clearAccountId();
      }
      return ResultOk(account);
    } on Exception {
      return const ResultError(StorageFailure());
    }
  }

  @override
  Future<Result<DemoAccount>> signIn(String email, String password) async {
    final account = DemoAccounts.byEmail(email);
    if (account == null || password != DemoAccounts.password) {
      return const ResultError(InvalidCredentialsFailure());
    }

    try {
      await _sessionStorage.writeAccountId(account.id);
      return ResultOk(account);
    } on Exception {
      return const ResultError(StorageFailure());
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _sessionStorage.clearAccountId();
      return const ResultOk(null);
    } on Exception {
      return const ResultError(StorageFailure());
    }
  }
}

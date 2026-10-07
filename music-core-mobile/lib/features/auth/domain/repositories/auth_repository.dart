import '../../../../core/result.dart';
import '../entities/demo_account.dart';

/// Source of truth for the current Demo account session.
abstract interface class AuthRepository {
  /// Restores the last account, or returns null when no session exists.
  Future<Result<DemoAccount?>> restoreSession();

  /// Signs in with one of the public Demo accounts.
  Future<Result<DemoAccount>> signIn(String email, String password);

  /// Ends the current local session without deleting account data.
  Future<Result<void>> signOut();
}

import '../../../../core/result.dart';
import '../entities/auth_session.dart';

/// Contract for authentication operations in the domain layer.
abstract interface class AuthRepository {
  /// Restores the last authenticated session, or returns null when not logged in.
  Future<Result<AuthSession?>> restoreSession();

  /// Authenticates with email and password via API Gateway.
  Future<Result<AuthSession>> signIn(String email, String password);

  /// Registers a new user account.
  Future<Result<void>> register({
    required String email,
    required String password,
    required String fullName,
    String? avatarUrl,
    String? phoneNumber,
    String? homeAddress,
  });

  /// Signs out and clears local session.
  Future<Result<void>> signOut();

  /// Refreshes the session using the saved refresh token.
  Future<Result<AuthSession>> refreshToken();
}

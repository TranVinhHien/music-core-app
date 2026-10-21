import 'package:meta/meta.dart';
import 'user_entity.dart';

/// Represents an active authenticated session.
@immutable
class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    this.refreshToken,
    this.sessionId,
  });

  final UserEntity user;
  final String accessToken;
  final String? refreshToken;
  final String? sessionId;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: UserEntity.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      accessToken: (json['access_token'] ?? json['token']) as String? ?? '',
      refreshToken: json['refresh_token'] as String?,
      sessionId: (json['session_id'] ?? json['sessionId']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'session_id': sessionId,
    };
  }

  AuthSession copyWith({
    UserEntity? user,
    String? accessToken,
    String? refreshToken,
    String? sessionId,
  }) {
    return AuthSession(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSession &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          accessToken == other.accessToken &&
          refreshToken == other.refreshToken &&
          sessionId == other.sessionId;

  @override
  int get hashCode =>
      user.hashCode ^
      accessToken.hashCode ^
      refreshToken.hashCode ^
      sessionId.hashCode;
}

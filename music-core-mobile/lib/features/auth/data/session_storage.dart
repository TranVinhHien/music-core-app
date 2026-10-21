import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/auth_session.dart';

/// Contract for persistent authentication session storage.
abstract interface class SessionStorage {
  Future<AuthSession?> readSession();

  Future<void> writeSession(AuthSession session);

  Future<void> clearSession();

  String? get cachedAccessToken;

  String? get cachedSessionId;
}

final class SharedPreferencesSessionStorage implements SessionStorage {
  SharedPreferencesSessionStorage(this._preferences);

  static const _sessionKey = 'active_auth_session';
  static const activeAccountKey = _sessionKey;

  final SharedPreferencesAsync _preferences;
  String? _inMemoryAccessToken;
  String? _inMemorySessionId;

  @override
  String? get cachedAccessToken => _inMemoryAccessToken;

  @override
  String? get cachedSessionId => _inMemorySessionId;

  @override
  Future<AuthSession?> readSession() async {
    try {
      final jsonString = await _preferences.getString(_sessionKey);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      final session = AuthSession.fromJson(map);
      _inMemoryAccessToken = session.accessToken;
      _inMemorySessionId = session.sessionId;
      return session;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeSession(AuthSession session) async {
    _inMemoryAccessToken = session.accessToken;
    _inMemorySessionId = session.sessionId;
    final jsonString = jsonEncode(session.toJson());
    await _preferences.setString(_sessionKey, jsonString);
  }

  @override
  Future<void> clearSession() async {
    _inMemoryAccessToken = null;
    _inMemorySessionId = null;
    await _preferences.remove(_sessionKey);
  }
}

import 'package:shared_preferences/shared_preferences.dart';

/// Persistence seam for the non-sensitive active Demo account identifier.
abstract interface class SessionStorage {
  Future<String?> readAccountId();

  Future<void> writeAccountId(String accountId);

  Future<void> clearAccountId();
}

final class SharedPreferencesSessionStorage implements SessionStorage {
  SharedPreferencesSessionStorage(this._preferences);

  /// Preference key for the non-sensitive active account identifier.
  static const activeAccountKey = 'active_demo_account_id';

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readAccountId() => _preferences.getString(activeAccountKey);

  @override
  Future<void> writeAccountId(String accountId) =>
      _preferences.setString(activeAccountKey, accountId);

  @override
  Future<void> clearAccountId() => _preferences.remove(activeAccountKey);
}
